Class ST_AI_Base extends AIController
	dependson(ST_Upgrades_Base);

var ST_Turret_Base TurretOwner;
var byte FailedTargetCount, FailedTargetThresh;

var byte TargetingPriority;
/* for reference from Globals.uci
`define TMODE_ANY		0
`define TMODE_STRONG	1
`define TMODE_WEAK		2
`define TMODE_RANGED	3
*/

event PostBeginPlay()
{
	Super.PreBeginPlay();
	Restart(false);
}

function Restart(bool bVehicleTransition)
{
	TurretOwner = ST_Turret_Base(Pawn);
	Enemy = None;
	InitPlayerReplicationInfo();

	GoToState('WaitForEnemy');
}

function InitPlayerReplicationInfo()
{
	if(PlayerReplicationInfo == None)
		PlayerReplicationInfo = Spawn(class'KFDummyReplicationInfo', self, , vect(0, 0, 0), rot(0, 0, 0));
	PlayerReplicationInfo.PlayerName="SentryTurret";		// TODO: change to refelct turret type
	if(WorldInfo.GRI != None && WorldInfo.GRI.Teams.Length > 0)
		PlayerReplicationInfo.Team = WorldInfo.GRI.Teams[0]; // TODO: This is where we'll assign team membership for versus
}

event Destroyed()
{
	if (PlayerReplicationInfo != None)
		CleanupPRI();
}

event SeePlayer(Pawn Seen)
{
	// For flavor: make a hello beep?
}
event SeeMonster(Pawn Seen)
{
	// Currently disabled because bIsPlayer = false
	// I think I can reenable it at any time though
}
event HearNoise(float Loudness, Actor NoiseMaker, optional Name NoiseType)
{
	// For flavor: do a scanning animation?
}

function NotifyTakeHit(Controller InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
{
	// Only process if damage was from a real pawn (versus environmental or programatic damage)
	if(InstigatedBy == None || InstigatedBy.Pawn == None)
		return;

	// Only set new enemy if pawn passes target test (plus an arbitrary buffer to reduce target bouncing)
	if(TestEnemy(InstigatedBy.Pawn) > TestEnemy(Enemy) + 30)
		SetEnemy(InstigatedBy.Pawn);
}

function SetEnemy(Pawn Other)
{
	ClearTimer('FindNextEnemy');
	Enemy = Other;
	TurretOwner.SetViewFocus(Enemy);
	GoToState('FightEnemy');
}

function int TestEnemy(Pawn Other)
{
	local int RtnWeight;

	switch(TargetingPriority)
	{
	case `TMODE_ANY:
		// Just returns distance
		return VSizeSq(Other.Location - TurretOwner.Location);
	case `TMODE_STRONG:
		// TODO: try to optimize to not use VSize()
		// Returns distance multiplied by max health
		return VSize(Other.Location - TurretOwner.Location) * Other.HealthMax; // Would like to use VSizeSq but we actually get close to integer max value
	case `TMODE_WEAK:
		// Returns distance divided by max health
		return VSizeSQ(Other.Location - TurretOwner.Location) / Other.HealthMax;
	case `TMODE_RANGED:
		// Returns distance scaled by modifiers per zed type
		// TODO: test would using a trinary operator here make this faster? wouldnt have to allocate RtnWeight
		RtnWeight = VSizeSq(Other.Location - TurretOwner.Location);
		if(Other.IsA('KFPawn_ZedSiren') || Other.IsA('KFPawn_ZedHusk') || Other.IsA('KFPawn_ZedDAR'))
		{
			return RtnWeight *= 0.5f;
		}
		return RtnWeight;
	default:
		// If no TargetingPriority is set or set wrong pick targets randomly
		return Rand(255);
	}
}

function bool IsValidTarget(Pawn Other)
{
	if(Other == none || !Other.IsAliveAndWell() || Other.IsSameTeam(Pawn) || !CanSee(Other))
		return false;
	return true;
}

final function FindBestEnemy(optional Pawn ExcludePawn)
{
	local Pawn TestPawn, BestPawn;
	local int TestWeight, BestWeight;
	
	foreach WorldInfo.AllPawns(class'Pawn', TestPawn, TurretOwner.Location, TurretOwner.SightRadius)
	{
		if(IsValidTarget(TestPawn))
		{
			if(TestPawn.Controller == None)
				continue;

			// Simulate zed seeing turret as a player even with bIsPlayer = false
			TestPawn.Controller.SeePlayer(TurretOwner);

			// Sort enemies and only hold the best one
			TestWeight = TestEnemy(TestPawn);

			// This uses ExcludePawn to weight all other pawns more heavily
			if(TestWeight < BestWeight / (1 + int(TestPawn == ExcludePawn)) || BestPawn == None)
			{
				BestPawn = TestPawn;
				BestWeight = TestWeight;
			}
		}
	}

	// If enemies are found switch to the best one
	if(BestPawn != none)
		SetEnemy(BestPawn);
}

simulated function bool CheckEnemyState()
{
	if(Enemy == None || !CanSee(Enemy) || !Enemy.IsAliveAndWell())
	{
		Enemy = none;
		GoToState('WaitForEnemy');
		return false;
	}
	
	return true;
}

function TargetBlocked()
{
	++FailedTargetCount;
	if(FailedTargetCount > FailedTargetThresh)
	{
		FailedTargetCount = 0;
		FindBestEnemy(Enemy);
	}
}

state WaitForEnemy // simulated to enable proxy 
{
	function BeginState(name OldState)
	{
		if(ROLE == ROLE_Authority)
		{
			FindBestEnemy(); // Look for a new enemy immediatly

			if(Enemy == None) // If we dont find an enemy the first time set up a timer to look again every 0.5 seconds
			{
				TurretOwner.SetViewFocus(None);
				TurretOwner.BeginScanning();
				SetTimer(0.5, true, 'FindBestEnemy');
			}
		}
		else
		{
			TurretOwner.SetViewFocus(None);
			TurretOwner.BeginScanning();
		}
	}

	function EndState(name NewState)
	{
		ClearTimer('FindBestEnemy');
		TurretOwner.EndScanning();
	}
}

auto state SetupState
{
	function BeginState(name OldState)
	{
		TurretOwner = ST_Turret_Base(Pawn);
		Enemy = None;
		InitPlayerReplicationInfo();

		GoToState('WaitForEnemy');
	}

	function EndState(name NewState)
	{
	}
}

state Disabled
{
	function BeginState(name OldState)
	{
	}

	function EndState(name NewState)
	{
	}
}

state FightEnemy
{
	function BeginState(name OldState)
	{
		TurretOwner.SetTimer(0.15f, false, 'BeginFiringPrimary'); // Server code only, executed in SetViewFocus for client
	}

	function EndState(name NewState)
	{
		// This covers all bases, if you dont need all this override the state and function to supply a slimmer set of calls
		TurretOwner.ClearTimer('BeginFiringPrimary');
		TurretOwner.ClearTimer('BeginFiringSecondary');
		TurretOwner.ClearTimer('BeginFiringSpecial');
		TurretOwner.ClearTimer('FirePrimary');
		TurretOwner.ClearTimer('FireSecondary');
		TurretOwner.ClearTimer('FireSpecial');
	}
}

defaultproperties
{
	// Experimental value for testing. Not sure how tunable this needs to be once I zero it in.
	FailedTargetThresh = 6
	TargetingPriority = `TMODE_ANY
}
