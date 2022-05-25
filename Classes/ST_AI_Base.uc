Class ST_AI_Base extends AIController
	dependson(ST_Upgrades_Base);

var ST_Turret_Base TurretOwner;
var vector LastAliveSpot;
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
	PlayerReplicationInfo.PlayerName="SentryTurret";
	if(WorldInfo.GRI != None && WorldInfo.GRI.Teams.Length > 0)
		PlayerReplicationInfo.Team = WorldInfo.GRI.Teams[0]; // This is one of the places well assign team membership for versus
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
}
event HearNoise(float Loudness, Actor NoiseMaker, optional Name NoiseType)
{
	// For flavor: do a scanning animation?
}

function NotifyTakeHit(Controller InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
{
	local int OtherWeight, EnemyWeight; // TODO: gotta be a better way to do this, maybe hold onto the enemies current weight?
	
	// Only process if damage was from a real pawn (versus environmental or programatic damage)
	if(InstigatedBy == None || InstigatedBy.Pawn == None)
		return;

	// Only set new enemy if pawn passes target test (plus an arbitrary buffer to reduce target bouncing)
	TestEnemy(InstigatedBy.Pawn, OtherWeight);
	TestEnemy(Enemy, EnemyWeight);
	if(OtherWeight > EnemyWeight + 30)
		SetEnemy(InstigatedBy.Pawn);
}

function SetEnemy(Pawn Other)
{
	ClearTimer('FindNextEnemy');
	Enemy = Other;
	TurretOwner.SetViewFocus(Enemy);
	GoToState('FightEnemy');
}

// Alter to return an int that represents it's targeting priority, 0 is invalid target, 1 is low
function TestEnemy(Pawn Other, out int RtnWeight)
{
	switch(TargetingPriority)
	{
	case `TMODE_ANY:
		// Just returns distance
		RtnWeight = VSizeSq(Other.Location - TurretOwner.Location);
		break;
	case `TMODE_STRONG:
		// Returns distance multiplied by max health
		RtnWeight = VSize(Other.Location - TurretOwner.Location) * Other.HealthMax; // Would like to use VSizeSq but we actually get close to integer max value
		break;
	case `TMODE_WEAK:
		// Returns distance divided by max health
		RtnWeight = VSizeSQ(Other.Location - TurretOwner.Location) / Other.HealthMax;
		break;
	case `TMODE_RANGED:
		// Returns distance scaled by modifiers per zed type
		RtnWeight = VSizeSq(Other.Location - TurretOwner.Location);
		if(KFPawn_ZedSiren(Other) != none)
		{
			RtnWeight *= 1.5f;
		}
		else if(KFPawn_ZedHusk(Other) != none)
		{
			RtnWeight *= 2.5f;
		}
		else if(KFPawn_ZedDAR(Other) != none)
		{
			RtnWeight *= 2.0f;
		}
		break;
	default:
		// If no TargetingPriority is set or set wrong pick targets randomly
		RtnWeight = Rand(255);
	}
}

function bool IsValidTarget(Pawn Other)
{
	if(Other == none || !Other.IsAliveAndWell() || Other.IsSameTeam(Pawn) || !CanSee(Other))
		return false;
	return true;
}

function Rotator GetAdjustedAimFor(Weapon W, vector StartFireLoc)
{
	if(Enemy != None && CanSee(Enemy));// CanSeeSpot(Enemy.Location, true))
		return rotator(TurretOwner.GetAimPos(StartFireLoc, Enemy) - StartFireLoc);
	return Super.GetAdjustedAimFor(W,StartFireLoc);
}

/*
final function bool CanTarget(vector P, optional bool bSkipTrace)
{
	return VSizeSq(P - TurretOwner.Location) < TurretOwner.IntSightRadius * TurretOwner.IntSightRadius && (Normal(P - TurretOwner.Location) Dot vector(TurretOwner.Rotation)) > TurretOwner.TurnRadius && (bSkipTrace || FastTrace(P, TurretOwner.GetTraceStart()));
}
*/

final function FindBestEnemy( optional Pawn ExcludePawn )
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
			TestEnemy(TestPawn, TestWeight);
			if(TestWeight < BestWeight || BestPawn == None)
			{
				BestPawn = TestPawn;
				BestWeight = TestWeight;
			}
		}
	}

	// If a better enemy is found than the current one switch to it
	if(BestPawn != none && BestPawn != Enemy)
	{
		SetEnemy(BestPawn);
	}
}

function CheckEnemyState()
{
	if(Enemy == None || !CanSee(Enemy) || !Enemy.IsAliveAndWell())
	{
		Enemy = none;
		ClearTimer('CheckEnemyState');
		GoToState('WaitForEnemy');
	}
}

state WaitForEnemy
{
	function BeginState(name OldState)
	{
		if(TurretOwner == None)
			return;

		FindBestEnemy(); // Look for a new enemy immediatly
		if(Enemy == None) // If we dont find an enemy the first time set up a timer to look again every 0.5 seconds
		{
			TurretOwner.SetViewFocus(None);
			SetTimer(0.5, true, 'FindBestEnemy');
		}
	}

	function EndState(name NewState)
	{
		ClearTimer('FindBestEnemy');
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
		if(TurretOwner == None)
			return;

		TurretOwner.PlaySoundBase(SoundCue'Turret_TF2.Sounds.sentry_spot_Cue');
		TurretOwner.SetTimer(0.18, false, 'DelayedStartFire'); // Give time to turn turret skeletal mesh then fire
		SetTimer(0.1, true, 'CheckEnemyState'); // 10 times a second check the current enemies is still valid
	}
	function EndState(name NewState)
	{
		ClearTimer('CheckEnemyState');

		// Stop shooting
		if(TurretOwner != None)
			TurretOwner.TurretSetFiring(false);
	}
}

defaultproperties
{
}
