// Main Turret class extends Pawn, but notably not _Monster or _Human
Class ST_Turret_Base extends KFPawn
	config(SentryRedux)
	dependson(ST_Upgrades_Base);

// STRUCTS
enum FireTypeEnums // Used to easily access each of the integrated weapons
{
	EPrimaryFire, // Example use: Damage[ESecondaryFire] will be the base damage the second integrated weapon does at any given time
	ESecondaryFire,
	ESpecialFire,

	ENumFireTypes // Used as int to cycle through fire types or use `NUM_WEAPONS, should always be equal
};

// OBJECTS
var ST_Upgrades_Base UpgradesObj; // The object that describes and knows what upgrades are currently purchased
var class<ST_Upgrades_Base> UpgradesClass; // Specifies which class type to use for the above object ^
var ST_Trigger_Base ActiveTrigger; // The object responsable for interactng with the player and opening the menu

// CACHED REFERENCES
var repnotify Pawn ViewFocusActor; // Where the turret mesh should be looking, set by server along with controller.enemy
var PlayerController OwnerController, LastOwner; // The player authorized to sell/downgrade the turret, the previous owner
var transient ST_Overlay LocalOverlay; // The completely local player overlay object to tie into HUD rendering
var transient ST_Settings_Rep Settings;
var transient ST_AI_Base AIController;

// STATS / GENERAL
var bool bRecentlyBuilt;
var float RefundMultiplier; // This is a fallback value and can be set at any time. This should really be determined by a Main Replicated Object.
var int DoshValue, IntSightRadius, BuildRadius; // IntSightRadius is used for faster Integer math when comparing distances
var float BuildTimer, NextTakeHitSound;
var repnotify bool bWasSold; // Notifies proxies of sale going on, only set by server

// WEAPONS - we have to use static arrays instead of dynamic arrays because dynamic arrays don't replicate quickly
var class<DamageType> DamageTypes[`NUM_WEAPONS];
var class<KFProjectile> ProjectileTypes[`NUM_WEAPONS];
var transient class<KFDamageType> TempDamageType; // Cached temporary value, faster to allocate once
var float AccuracyMod[`NUM_WEAPONS], TurnRadius, RoF[`NUM_WEAPONS], NextFireSoundTime;
var int WeaponRange[`NUM_WEAPONS], AmmoCount[`NUM_WEAPONS], MaxAmmoCount[`NUM_WEAPONS], Damage[`NUM_WEAPONS];
var int TempDamage; // Float rather than int to allow precise muilti-float calculations nb efore using Round(), pulled from Weapon.uc
var vector AimTarget; // Moving away from this being replicated, its just where to render the hit fx
var repnotify byte FireCounter[`NUM_WEAPONS];
var transient class<KFProjectile> WeaponProjectiles[`NUM_WEAPONS];

// ANIMATION / FX
var KFMuzzleFlash MuzzleFlash[4]; // Arbitrary, we can increase this as necesssary
var byte MuzzleFlashIndex;
var AnimNodeSlot AnimationNode, UpperAnimNode;
var float ScanLocTimer;
var SkelControlLookAt YawControl, PitchControl;
var bool bIsScanning, bLeftScanned, bAltMissileFired;
var vector ScanLocation, DesScanLocation;
var Name MuzzleNames[2];

// SOUND
var SoundCue FiringSounds[`NUM_WEAPONS];
var SoundCue EmptySounds[`NUM_WEAPONS];
var SoundCue ScanningSound;
var SoundCue DamageTakenSound;
var SoundCue DieingSound;

// REPLICATION
replication
{
	if(bNetDirty)
		bWasSold, ViewFocusActor, DoshValue, bRecentlyBuilt, FireCounter, AmmoCount, OwnerController;
}

simulated event ReplicatedEvent(name VarName)
{
	switch(VarName)
	{
	case 'ViewFocusActor':
		SetViewFocus(ViewFocusActor);
		break;
	case 'OwnerController':
		OwnerChanged();
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}

// FUNCTIONS
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	SetTimer(0.2, true, 'RetryFetchSettings');
	RetryFetchSettings();

	CreateTrigger();

	// Initiates green overlay text on clients, ignored for server
	if(WorldInfo.NetMode != NM_DedicatedServer)
		AddHUDOverlay();

	// Spawns AI object as defined in the default properties
	if(Controller == None)
		SpawnDefaultController();
	AIController = ST_AI_Base(Controller); // Assigns a reference to the AI object thats typed and easily accessible
}

// Handles removing local entries for old owner and creating local entries for new owner
simulated function OwnerChanged()
{
	if(Settings != none && LastOwner != OwnerController)
	{
		Settings.LocalTurretDestroyed(LastOwner);
		Settings.LocalTurretCreated(OwnerController);
		LastOwner = OwnerController;
	}
}

simulated function RetryFetchSettings()
{
	if(Settings == none)
		Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);
	if(Settings != none && Settings.bInitialized)
	{
		ClearTimer('RetryFetchSettings');
		Settings.TurretCreated(Self); // Adds reference to self to the list of turrets stored in Settings object
		LastOwner = OwnerController;
		Settings.LocalTurretCreated(OwnerController);
	}
	else
	{
		`log("ST_Turret_Base: Server Settings not initialized, rechecking in 0.2");
	}
}

// NOT simulated, can only be run with ROLE_Authority
function CreateTrigger()
{
	// Create a collision actor that enables the 'Use' message to appear for clients and enables opening the turret upgrade menu
	ActiveTrigger = Spawn(class'ST_Trigger_Base');
	ActiveTrigger.TurretOwner = Self;
	ActiveTrigger.SetBase(Self);

	// Create an object that defines what upgrades are available and what they do
	UpgradesObj = Spawn(UpgradesClass, Self);
	UpgradesObj.SetTurretOwner(Self);
}

simulated function InitBuild()
{
	// Reset skeletal mesh to default orientation
	SetViewFocus(None);

	// Stop the scanning animation
	if(bIsScanning)
		EndScanning();

	PreBuildAnimation(); // TODO: is there any optimization when using events instead of functions?
	// Fetch the build animation length in seconds then queue PostBuildAnimation() when it finishes
	BuildTimer = FMax(AnimationNode.PlayCustomAnim('Build',1.f,0.f,0.f,false,true), UpperAnimNode.PlayCustomAnim('Build',1.f,0.f,0.f,false,true));

	SetTimer(BuildTimer, false, 'PostBuildAnimation');
}

simulated function PreBuildAnimation()
{
	// Disable AI targeting during build animation
	if(AIController != None && ROLE == ROLE_Authority)
		AIController.GoToState('Disabled');
	bRecentlyBuilt = true;
}

simulated function PostBuildAnimation()
{
	// Reenable AI targeting
	if(AIController != None && ROLE == ROLE_Authority)
		AIController.GoToState('WaitForEnemy');
	bRecentlyBuilt = false; // Tells joining players not to play build animation
}

// Client side only, sets turret mesh, anims, and materials
simulated function UpdateDisplayMesh()
{
	local MaterialInterface TempMat;
	local int i;

	RemoveMuzzles();

	AnimationNode = None;
	UpperAnimNode = None;

	Mesh.SetSkeletalMesh(UpgradesObj.LevelInfos[UpgradesObj.TurretLevel].TurretArch.CharacterMesh);
	Mesh.AnimSets = UpgradesObj.LevelInfos[UpgradesObj.TurretLevel].TurretArch.AnimSets;
	Mesh.SetAnimTreeTemplate(UpgradesObj.LevelInfos[UpgradesObj.TurretLevel].TurretArch.AnimTreeTemplate);
	Mesh.SetPhysicsAsset(UpgradesObj.LevelInfos[UpgradesObj.TurretLevel].TurretArch.PhysAsset);

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		foreach UpgradesObj.LevelInfos[UpgradesObj.TurretLevel].TurretArch.Skins(TempMat, i)
		{
			Mesh.SetMaterial(i, TempMat);
		}
	}

	UpdateSounds();
}
simulated function UpdateSounds(); // Implement in child classes if soundcues change when the model does

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	AnimationNode = AnimNodeSlot(SkelComp.FindAnimNode('AnimBody'));
	if(UpgradesObj.TurretLevel == 2)
		UpperAnimNode = AnimNodeSlot(SkelComp.FindAnimNode('Cannon'));
	YawControl = SkelControlLookAt(SkelComp.FindSkelControl('YawBone'));
	PitchControl = SkelControlLookAt(SkelComp.FindSkelControl('PitchBone'));

	Super(Pawn).PostInitAnimTree(SkelComp);

	if(bRecentlyBuilt)
	{
		InitBuild();
	}
	else
	{
		PostBuildAnimation();
	}
}

simulated final function AddHUDOverlay()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if(PC == None)
	{
		`log("ST_Overlay: AddHUDOverlay() failed, PC is None");
		return;
	}

	LocalOverlay = class'ST_Overlay'.Static.GetOverlay(PC, WorldInfo);
	LocalOverlay.ActiveTurrets.AddItem(Self);
}

simulated final function SetSightRadius(float NewRadius)
{
	SightRadius = NewRadius;
	IntSightRadius = NewRadius; // Casts the float down to an integer. IntSightRadius is used repeatedly by the AI (Assumed faster)
}

simulated final function SetTurnRadius(float NewTurn)
{
	// Used by AI in CanSee() calls
	PeripheralVision = NewTurn;
}

// Check if owner player disconnects from server
function CheckUserConnected()
{
	if(OwnerController == None)
	{
		Health -= Settings.TurretHealthTickDown;

		if(Health <= 0) // Not sure this should be here, seams like something thats already handled by tripwire
			KilledBy(None);
	}
}

function SetTurretOwner(PlayerController Other)
{
	ClearTimer('CheckUserConnected');
	SetTimer(4, true, 'CheckUserConnected');

	OwnerController = Other;
	if(Other != none) // This avoids accessing Other when it's none and throwing a script warning
	{
		PlayerReplicationInfo = Other.PlayerReplicationInfo; // Makes it so we earn dosh for our turret kills
	}
	else
	{
		PlayerReplicationInfo = none;
	}
}

function int AddAmmo(coerce byte Index, int Amount) // Intentionally cast Index to byte for faster overflow checking
{
	local int AmountAdded;

	if(Index < 3)
	{
		AmountAdded = Min(Amount, MaxAmmoCount[Index] - AmmoCount[Index]);
		AmmoCount[Index] += AmountAdded;
	}

	return AmountAdded; // Base dosh charged for purchase on this value
}

// Used by ST_Overlay to get formatted text describing the turret
simulated function string GetInfo()
{
	return (PlayerReplicationInfo != None ? (PlayerReplicationInfo.PlayerName $ "'s") : "No Owner") $ " (" $ GetHealth() $ " HP)";
}

// Used by menus to get turret owner name
simulated function string GetOwnerName()
{
	return PlayerReplicationInfo != None ? PlayerReplicationInfo.PlayerName : "No Owner";
}

// Used by menus to get current health as percent
simulated function string GetHealth()
{
	return Round((float(Health) / float(HealthMax)) * 99.f + 1) $ "%"; // Puts the percentage in the range of 1 to 100 so it never reads 0%;
}

// Used by ST_Overlay to get formatted text describing the turret
simulated function string GetAmmoStatus(optional int Index = 3)
{
	local string S;
	local int i;
	//If Index is out of array bounds gather all ammo stats
	if(Index >= 3)
	{
		S = GetAmmoStatus(0); //Recursively get ammocount for index 0
		for(i = 1; i < 3; i++)
		{
			if(MaxAmmoCount[i] != 0)
			{
				S $= " - " $ GetAmmoStatus(i); //Recursively get ammocounts if MaxAmmoCount != 0
			}
		}
	}
	else //If Index is within array bounds return ammo count for that index
	{
		return AmmoCount[Index]$"/"$MaxAmmoCount[Index];
	}
	
	return S;
}

// Swings the model to point towards the targeted zed, 
simulated function SetViewFocus(Pawn Other)
{
	if(ROLE == ROLE_Authority) // replicated to client, set on server
		ViewFocusActor = Other;
	if(WorldInfo.NetMode == NM_DedicatedServer) // everything below here is visual and not eexecuted on server
		return;

	// It seems unecessary to lock the skeleton in this particular way, we could just give it a default vector location to look at when not scanning or tracking an enemy right?
	if(Other == None)
	{
		YawControl.SetSkelControlStrength(0.0f, 0.15f);
		if(PitchControl != None)
		{
			PitchControl.SetSkelControlStrength(0.0f, 0.15f);
		}

		ClearTimer('BeginFiringPrimary');
		ClearTimer('BeginFiringSecondary');
		ClearTimer('BeginFiringSpecial');
		ClearTimer('FirePrimary');
		ClearTimer('FireSecondary');
		ClearTimer('FireSpecial');
	}
	else
	{
		YawControl.SetSkelControlStrength(1.0f, 0.15f);
		if(PitchControl != None)
		{
			PitchControl.SetSkelControlStrength(1.0f, 0.15f);
		}

		PlaySoundBase(SoundCue'Turret_TF2.Sounds.sentry_spot_Cue');
		SetTimer(0.15f, false, 'BeginFiringPrimary');
		//SetTimer('BeginFiringSecondary');
		//SetTimer('BeginFiringSpecial');
	}
}

simulated function Tick(float Delta)
{
	if(WorldInfo.NetMode != NM_DedicatedServer && Health > 0)
	{
		if(ViewFocusActor != None)
		{
			YawControl.SetTargetLocation(ViewFocusActor.Location);
			YawControl.InterpolateTargetLocation(Delta);
			if(PitchControl != None)
			{
				PitchControl.SetTargetLocation(ViewFocusActor.Location);
				PitchControl.InterpolateTargetLocation(Delta);
			}
		}
		else if(bIsScanning)
		{
			if(ScanLocTimer < WorldInfo.TimeSeconds)
				PickNextScanLocation();
			SetScanLocation();
			YawControl.InterpolateTargetLocation(Delta);
			if(PitchControl != None)
				PitchControl.InterpolateTargetLocation(Delta);
		}
	}
}
simulated final function PickNextScanLocation()
{
	local vector X, Y, Z;
	
	ScanLocation = DesScanLocation;
	GetAxes(Rotation, X, Y, Z);
	DesScanLocation = Normal(X + (bLeftScanned ? Y : -Y) * 0.325);
	bLeftScanned = !bLeftScanned;
	ScanLocTimer = WorldInfo.TimeSeconds + 1.05f;
}
simulated final function SetScanLocation()
{
	local float T;
	local vector V;
	
	T = (ScanLocTimer - WorldInfo.TimeSeconds) / 1.05f;
	V = Location + (ScanLocation * T + DesScanLocation * (1.0f - T)) * 5000.0f;
	YawControl.SetTargetLocation(V);
	if(PitchControl != None)
		PitchControl.SetTargetLocation(V);
}

function bool TryToSellTurret(Controller User)
{
	if(OwnerController == User)
	{
		bWasSold = true;
		if(User.PlayerReplicationInfo != None)
			User.PlayerReplicationInfo.Score += (DoshValue * RefundMultiplier);
		
		KilledBy(None);
		return true;
	}

	else if(PlayerController(User) != None)
		PlayerController(User).ReceiveLocalizedMessage(class'ST_LocalMessage', 5);
	return false;
}

// Called from AI
simulated function BeginScanning()
{
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		ScanLocation = vector(Rotation);
		DesScanLocation = ScanLocation;
		AnimationNode.StopCustomAnim(0.05f);
		bIsScanning = true;
		SetTimer(0.2f, false, 'ScanSound');
		SetTimer(6.0f, false, 'EndScanning');
	}
}
	
simulated function ScanSound()
{
	if(ScanningSound == None || !bIsScanning)
		return;

	PlaySoundBase(ScanningSound, true);
	SetTimer(ScanningSound.GetCueDuration(), false, 'ScanSound');
}
simulated function EndScanning() // Can be called on timer or from AI
{
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		bIsScanning = false;
		ClearTimer('ScanSound');
	}
}

// The 3 weapon slots have their own function calls for optimization
simulated function BeginFiringPrimary()
{
	SetTimer(RoF[EPrimaryFire], true, 'FirePrimary');
}
simulated function BeginFiringSecondary()
{
	SetTimer(RoF[ESecondaryFire], true, 'FireSecondary');
}
simulated function BeginFiringSpecial()
{
	SetTimer(RoF[ESecondaryFire], true, 'FireSecondary');
}

simulated function FirePrimary()
{
	// More efficient to do this here than in a seperate timer
	if(ROLE == ROLE_Authority && !AIController.CheckEnemyState())
	{
		return; // If the enemy is dead or can't be targeted just dont shoot
	}

	if(AmmoCount[EPrimaryFire] < 1)
	{
		if(WorldInfo.NetMode != NM_DedicatedServer)
		{
			PlayPrimaryOutOfAmmo();
		}
		return;
	}

	if(ROLE == ROLE_Authority)
	{
		--AmmoCount[EPrimaryFire];
		++FireCounter[EPrimaryFire];
	}

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		AnimationNode.PlayCustomAnim('Fire', 1.0f, 0.0f, 0.0f, false, true);
		if(NextFireSoundTime < WorldInfo.TimeSeconds)
		{
			NextFireSoundTime = WorldInfo.TimeSeconds + 0.15f; // TODO: This is an arbitrary time, how do we fetch the soundcue length instead?
			PlaySoundBase(FiringSounds[EPrimaryFire], true);
		}
	}
}

simulated function FireSecondary()
{
	// More efficient to do this here than in a seperate timer
	if(ROLE == ROLE_Authority && !AIController.CheckEnemyState())
		return; // If the enemy is dead or can't be targeted just dont shoot

	if(AmmoCount[ESecondaryFire] <= 0)
	{
		if(WorldInfo.NetMode != NM_DedicatedServer)
			PlayPrimaryOutOfAmmo();
		return;
	}

	if(ROLE == ROLE_Authority)
	{
		--AmmoCount[ESecondaryFire];
		++FireCounter[ESecondaryFire];
	}

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		AnimationNode.PlayCustomAnim('Fire', 1.0f, 0.0f, 0.0f, false, true);
		if(NextFireSoundTime < WorldInfo.TimeSeconds)
		{
			NextFireSoundTime = WorldInfo.TimeSeconds + 0.15f; // TODO: This is an arbitrary time, how do we fetch the soundcue length instead?
			PlaySoundBase(FiringSounds[ESecondaryFire], true);
		}
	}
}

simulated function FireSpecial()
{
}

simulated function PlayPrimaryOutOfAmmo()
{
	PlaySoundBase(EmptySounds[EPrimaryFire], true);
}

function CheckFireMissile()
{
	local Pawn TargetPawn;
	local KFPawn tempPawn;
	local int HealthPool;
	local rotator ProjRotation;
	local vector StartLocation;
	local ST_Proj_Missile Proj;
	
	TargetPawn = Controller.Enemy;
	if(TargetPawn == None)
		return;
	
	foreach WorldInfo.AllPawns(class'KFPawn', tempPawn, TargetPawn.Location, 600.0f) // TODO: instead of 600 tie this range to the damage radius of the projectile to be used
	{
		if(tempPawn == TargetPawn || FastTrace(tempPawn.Location, TargetPawn.Location))
			HealthPool += (200 + tempPawn.Health);
	}
	
	if(HealthPool > 800)
	{
		//NextMissileTimer = WorldInfo.TimeSeconds + 3.8f;
		if(++FireCounter[EPrimaryFire] > 250)
			FireCounter[EPrimaryFire] = 1;
		if(WorldInfo.NetMode != NM_DedicatedServer)
			MakeFireMissileFX();
		
		// Fire proj itself.
		StartLocation = Location + vect(0, 0, 122.0f); // Offset to put missile outside the turrets collision
		ProjRotation = rotator(GetAimPos(StartLocation, ViewFocusActor) - StartLocation);
		Proj = ST_Proj_Missile(Spawn(ProjectileTypes[ESecondaryFire], , , StartLocation, ProjRotation));
		if(Proj != None)
		{
			if(UpgradesObj.HasUpgrade(EUpWeaponBehaviour))
				Proj.AimTarget = TargetPawn;
			Proj.Damage = Damage[1];
			Proj.ExplosionTemplate.Damage = Damage[1];
			Proj.Init(vector(ProjRotation));
			Proj.InstigatorController = OwnerController != None ? OwnerController : Controller;
			Proj.Speed = 1500;
		}
	}
}

simulated function MakeFireMissileFX()
{
	local byte i;
	local name M;

	bAltMissileFired = !bAltMissileFired;
	i = 2 + byte(bAltMissileFired);
	M = bAltMissileFired ? 'RoMuz' : 'RoMuz2';
	UpperAnimNode.PlayCustomAnim('FireRocket', 1.0f, 0.0f, 0.0f, false, true);
	
	if (MuzzleFlash[i] == None)
	{
		MuzzleFlash[i] = new(self) Class'KFMuzzleFlash'(KFMuzzleFlash'WEP_AA12_ARCH.Wep_AA12Shotgun_MuzzleFlash_3P');
		MuzzleFlash[i].AttachMuzzleFlash(Mesh, M, M);
		MuzzleFlash[i].MuzzleFlash.PSC.SetScale(3.5f);
	}
	MuzzleFlash[i].CauseMuzzleFlash(0);
}

// Gets the bullet spawn height, logic is mesh dependant
simulated final function vector GetTraceStart()
{
	return Location + (UpgradesObj.TurretLevel == 0 ? vect(0, 0, 38.0f) : vect(0, 0, 77.0f));
}

simulated function vector GetAimPos(vector CamLoc, Pawn TPawn)
{
	local vector			HitLocation, HitNormal, TorsoLocation, tempLocation;
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;

	// if bHeadhunter upgrade Check to see if we can hit the head
	if(UpgradesObj.HasUpgrade(EUpHeadshots))
	{
		tempLocation = TPawn.Mesh.GetBoneLocation(HeadBoneName);
		HitActor = TPawn.Trace(HitLocation, HitNormal, tempLocation, CamLoc, TRUE, vect(0,0,0), HitInfo, TRACEFLAG_Bullet);
		if( HitActor == none || HitActor == Self || HitActor == TPawn)
		{
			return tempLocation; //+ (vect(0,0,-10.0)); // I don't remember why we were shooting low on the head-bone, I think its leftover from shooting high on the torso
		}
	}
	// Try for the torso
	TorsoLocation = TPawn.Mesh.GetBoneLocation(TorsoBoneName);
	HitActor = TPawn.Trace(HitLocation, HitNormal, TorsoLocation, CamLoc, TRUE, vect(0,0,0), HitInfo, TRACEFLAG_Bullet);
	if( HitActor == none || HitActor == Self || HitActor == TPawn)
	{
		return TorsoLocation;
	}
	// Try for the pelvis
	tempLocation = TPawn.Mesh.GetBoneLocation(PelvisBoneName);
	HitActor = TPawn.Trace(HitLocation, HitNormal, tempLocation, CamLoc, TRUE, vect(0,0,0), HitInfo, TRACEFLAG_Bullet);
	if( HitActor == none || HitActor == Self || HitActor == TPawn)
	{
		return tempLocation;
	}
	// Return the torso location by default
	// TODO: We could keep track of these and switch targets after a number of bad shots
	return TorsoLocation;
}

simulated function FireBullet()
{
	local vector StartLocation, EndLocation, Dir, HitLocation, HitNormal;
	local Actor HitActor;
	local TraceHitInfo HitInfo;
	local int HitZoneIndex;

	if(ViewFocusActor == none)
		return;

	StartLocation = GetTraceStart();
	AimTarget = GetAimPos(StartLocation, ViewFocusActor);
	Dir = VRandCone(Normal(AimTarget - StartLocation), AccuracyMod[EPrimaryFire]); // Official way, should be faster than Marco's. Angle is in radians
	EndLocation = StartLocation + Dir * WeaponRange[EPrimaryFire];

	// TODO: implement fasttrace for ROLE != ROLE_Authority instead of recursive trace?

	// I'm not happy about having to make this but its almost always going to be faster than Marco's way. This design concept is from Weapon.uc
	RecursiveBulletTrace(HitActor, HitLocation, HitNormal, EndLocation, StartLocation, HitInfo);

	// N.B. - The goal is to have the client simulate firing and hitting but only the server actually dealing damage, server needs to replicate damage notification to client for damage numbers to pop up
	// If trace hit a pawn (not on same team) deal damage
	if(ROLE == ROLE_Authority)
	{
		if(KFPawn(HitActor) != none)
		{
			// Set up and run damage modification on both client and server
			TempDamage = Damage[EPrimaryFire];
			TempDamageType = class<KFDamageType>(DamageTypes[EPrimaryFire]);
			HitZoneIndex = HitZones.Find('ZoneName', HitInfo.BoneName);
			UpgradesObj.ModifyDamageGiven(TempDamage, HitActor, TempDamageType, HitZoneIndex);

			Controller.bIsPlayer = false;

			HitActor.TakeDamage(TempDamage, (OwnerController != None ? OwnerController : Controller), HitLocation, Dir * 10000.f, TempDamageType, HitInfo, Self);
			KFPawn(HitActor).AddHitFX(TempDamage, Controller, HitZoneIndex, HitLocation, Dir * 10000.f, TempDamageType);

			if(Controller != None) // Enemy may have exploded and killed the turret, check before assuming access to variable
				Controller.bIsPlayer = true;
			
			if(Pawn(HitActor).Controller != None) // Enemy may have been killed by the shot in which case they cant be notified
				Pawn(HitActor).Controller.NotifyTakeHit(Controller, HitLocation, TempDamage, TempDamageType, Dir); // Add aggro to the hit pawn
		}
		else
		{
			AIController.TargetBlocked(); // Server side logic for switching targets
		}
	}
	
	// Client side graphical effects
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		DrawBulletFX(HitActor, HitLocation, HitNormal);
	}
}

simulated function RecursiveBulletTrace(out actor HitActor, out vector HitLocation, out vector HitNormal, vector EndTrace, vector StartTrace, out TraceHitInfo HitInfo, optional vector Extent) // Helper function to efficiently find a bullets resting place
{
	local actor TempActor;
	local bool bOldBlockActors, bOldCollideActors;

	TempActor = Trace(HitLocation, HitNormal, EndTrace, StartTrace, TRUE, Extent, HitInfo, TRACEFLAG_Bullet);
	// If we didn't hit anything, then set the HitLocation as being the EndTrace location
	if( TempActor == None )
	{
		HitLocation	= EndTrace;
		return;
	}
	else
	{
		// This statement allows passing through permiable barriers and teammates
		if (!TempActor.bBlockActors || TempActor.IsA('Trigger') || TempActor.IsA('TriggerVolume') || TempActor.IsA('InteractiveFoliageActor') || (Pawn(TempActor) != none && Pawn(TempActor).IsSameTeam(Self)))
		{
			TempActor.bProjTarget = false;
			bOldCollideActors = TempActor.bCollideActors;
			bOldBlockActors = TempActor.bBlockActors;

			if (TempActor.IsA('Pawn'))
			{
				TempActor.SetCollision(false, false);
			}
			else
			{
				if( bOldBlockActors )
				{
					TempActor.SetCollision(bOldCollideActors, false);
				}
			}
			RecursiveBulletTrace(HitActor, HitLocation, HitNormal, EndTrace, HitLocation, HitInfo, Extent);
			TempActor.bProjTarget = true; 	// Not sure this is relavent
			TempActor.SetCollision(bOldCollideActors, bOldBlockActors);
		}
		else
		{
			// In Weapon.uc there is code here for bullets going through portals and hitting stuff on the other side. Fuck that for many reasons.
			HitActor = TempActor;
		}
	}
}

simulated function FireProjectile()
{
}

simulated function FireProjectileLobbed()
{
}

simulated function DrawBulletFX(Actor TargetActor, vector HitLocation, vector HitNormal)
{
	local ParticleSystemComponent Emitter;
	local vector Start, Dir;
	local float Dist;
	
	if(UpgradesObj.TurretLevel > 0)
	{
		MuzzleFlashIndex = 1 - MuzzleFlashIndex;
	}

	if (MuzzleFlash[MuzzleFlashIndex] == None)
	{
		MuzzleFlash[MuzzleFlashIndex] = new(self) Class'KFMuzzleFlash'(KFMuzzleFlash'WEP_AA12_ARCH.Wep_AA12Shotgun_MuzzleFlash_3P');
		MuzzleFlash[MuzzleFlashIndex].AttachMuzzleFlash(Mesh, MuzzleNames[MuzzleFlashIndex], MuzzleNames[MuzzleFlashIndex]);
		MuzzleFlash[MuzzleFlashIndex].MuzzleFlash.PSC.SetScale(2.5f);
	}
	MuzzleFlash[MuzzleFlashIndex].CauseMuzzleFlash(0);
	
	
	/*if(TargetActor != None)
	{
		KFImpactEffectManager(WorldInfo.MyImpactEffectManager).PlayImpactEffects(HitLocation, self, HitNormal, KFImpactEffectInfo'FX_Impacts_ARCH.Light_bullet_impact');
	}*/

	Mesh.GetSocketWorldLocationAndRotation(MuzzleNames[MuzzleFlashIndex], Start);
	Dir = HitLocation - Start;
	
	Dist = VSizeSq(Dir);
    if ( Dist > 40000 ) // From KFWeaponAttachment.uc
    {
    	// Lifetime scales based on the distance from the impact point. Subtract a frame so it doesn't clip.
		Dist = fMin( (Sqrt(Dist) - 100.f) / 7000, 1.f );
		if( Dist > 0.f )
		{
	   		Emitter = WorldInfo.MyEmitterPool.SpawnEmitter( ParticleSystem'FX_Projectile_EMIT.FX_Common_Tracer_Instant', Start, rotator(Dir) );
			Emitter.SetVectorParameter( 'Tracer_Velocity', vect(7000, 0, 0));
			Emitter.SetFloatParameter( 'Tracer_Lifetime', Dist );
		}
    }
}

simulated function KFSkinTypeEffects GetHitZoneSkinTypeEffects(int HitZoneIdx)
{
	// This defines the FX when the turret is shot
	return KFSkinTypeEffects'FX_Impacts_ARCH.SkinTypes.Metal';
}

/*
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	return Super.Died(Killer, DamageType, HitLocation);
}*/

simulated function Destroyed()
{
	if(OwnerController != none && Settings != none)
		Settings.LocalTurretDestroyed(OwnerController);

	if(WorldInfo.NetMode != NM_Client && Settings != none)
	{
		Settings.TurretDestroyed(self);
	}

	if(LocalOverlay != None)
		LocalOverlay.ActiveTurrets.RemoveItem(Self);

	RemoveMuzzles();
	if(ActiveTrigger != None)
	{
		ActiveTrigger.Destroy();
		ActiveTrigger = None;
	}

	UpgradesObj.Destroy();

	Super.Destroyed();
}

simulated final function RemoveMuzzles()
{
	local byte i;
	
	for(i = 0; i < ArrayCount(MuzzleFlash); ++i)
		if (MuzzleFlash[i] != None)
		{
			MuzzleFlash[i].DetachMuzzleFlash(Mesh);
			MuzzleFlash[i] = None;
		}
}

simulated final function SetFloorOrientation(vector LandNormal)
{
	local vector X, Y, Z;
	local rotator R;

	R.Yaw = Rotation.Yaw;
	if(LandNormal.Z > 0.997f || LandNormal.Z <= 0.2f)
	{
		SetRotation(R);
		return;
	}

	// Fast dummy method for making it adjust to ground direction.
	GetAxes(R, X, Y, Z);
	X = Normal(X - LandNormal * (X Dot LandNormal));
	Y = Normal(Y - LandNormal * (Y Dot LandNormal));
	Z = (X Cross Y);
	SetRotation(OrthoRotation(X, Y, Z));
}

event Landed(vector HitNormal, Actor FloorActor)
{
	SetPhysics(PHYS_None);
	SetFloorOrientation(HitNormal);
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{	
	Super.PlayDying(DamageType, HitLoc);
	
	if(!bWasSold && WorldInfo.NetMode != NM_DedicatedServer)
	{
		PlaySoundBase(DieingSound, true);
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'WEP_3P_EMP_EMIT.FX_EMP_Grenade_Explosion', Location);
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'WEP_3P_MKII_EMIT.FX_MKII_Grenade_Explosion', Location);
	}
	
	if(ActiveTrigger != None)
	{
		ActiveTrigger.Destroy();
		ActiveTrigger = None;
	}
}

simulated function PlayHit(float InDamage, Controller InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum, TraceHitInfo HitInfo)
{
	if(InDamage > 5 && NextTakeHitSound < WorldInfo.TimeSeconds)
	{
		NextTakeHitSound = WorldInfo.TimeSeconds + 1.5f; // Up from 0.5
		PlaySoundBase(DamageTakenSound);
	}
}

simulated event bool CanDoSpecialMove(ESpecialMove AMove, optional bool bForceCheck)
{
	return false;
}

function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling, optional bool bAllowSameTeamGrab)
{
	return false;
}

event bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType, optional bool bCanRepairArmor = true, optional bool bMessageHealer = true)
{
	if(Amount > 0 && IsAliveAndWell() && Health < HealthMax)
	{
		Amount = Min(Amount, HealthMax - Health);
		Health += Amount;
		if(KFPlayerController(Healer) != None)
			KFPlayerController(Healer).AddWeldPoints(Amount << 1);
		return true;
	}
	return false;
}

event TakeDamage(int InDamage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	/*
	if(DamageType == class'KFDT_Custom_Turret_Heal')
	{
		HealDamage(InDamage, InstigatedBy, DamageType);
		return;
	}
	*/
	
	if(InstigatedBy != None && InstigatedBy.GetTeamNum() == GetTeamNum())
		return;

	Super.TakeDamage(InDamage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

function AddVelocity(vector NewVelocity, vector HitLocation, class<DamageType> damageType, optional TraceHitInfo HitInfo);

function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	UpgradesObj.ModifyDamageTaken(InDamage, DamageType, InstigatedBy);

	// TODO: This call accounts for game difficulty and stuff; We may want to reimplement this code
	Super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);
}

defaultproperties
{
	bWasSold = false
	bRecentlyBuilt = true

	UpgradesClass = class'ST_Upgrades_Base'

	Mass = 5500.0
	BaseEyeHeight = 70.0
	EyeHeight = 70.0
	Health = 350 // Immediatly overwritten by config, ensures turret isnt spawnerd with 0 health
	HealthMax = 350 // Immediatly overwritten by config, ensures turret isnt spawnerd with 0 health
	ControllerClass = Class'ST_AI_Base'
	RefundMultiplier = 1.0f // N.B. - While this is a hardcoded 100% mercy refund amount by default, we'll still make this set by the settings
	WeaponRange(EPrimaryFire) = 10000.0f // Default for bullet tracing, decrease for ammo with limited range; Used to limit the range at which zeds are considered for attack and how far out to raytrace

	DamageTypes(0) = class'KFDT_Ballistic'
	ProjectileTypes(ESecondaryFire) = class'ST_Proj_Missile'

	MuzzleNames(0) = "Muz"
	MuzzleNames(1) = "Muz2"


	Begin Object Name=ThirdPersonHead0
		ReplacementPrimitive = None
		bAcceptsDynamicDecals = True
	End Object
	ThirdPersonHeadMeshComponent = ThirdPersonHead0

	Begin Object Class=KFAfflictionManager Name=Afflictions_0 Archetype = KFAfflictionManager'KFGame.Default__KFPawn:Afflictions_0'
		FireFullyCharredDuration = 2.5
		FireCharPercentThreshhold = 0.25
	End Object
	AfflictionHandler = KFAfflictionManager'Default__ST_Turret_Base:Afflictions_0'

	Begin Object Name=FirstPersonArms
		bIgnoreControllersWhenNotRendered = True
		bOverrideAttachmentOwnerVisibility = True
		bAllowBooleanPreshadows = False
		ReplacementPrimitive = None
		DepthPriorityGroup = SDPG_Foreground
		bOnlyOwnerSee = True
		bAllowPerObjectShadows = True
	End Object
	ArmsMesh = FirstPersonArms

	Begin Object Class=KFSpecialMoveHandler Name=SpecialMoveHandler_0 Archetype = KFSpecialMoveHandler'KFGame.Default__KFPawn:SpecialMoveHandler_0'
	End Object
	SpecialMoveHandler = KFSpecialMoveHandler'Default__ST_Turret_Base:SpecialMoveHandler_0'

	Begin Object Name=AmbientAkSoundComponent_1
		BoneName="Dummy"
		bStopWhenOwnerDestroyed = True
	End Object
	AmbientAkComponent = AmbientAkSoundComponent_1

	Begin Object Name=AmbientAkSoundComponent_0
		BoneName="Dummy"
		bStopWhenOwnerDestroyed = True
		bForceOcclusionUpdateInterval = True
	End Object
	WeaponAkComponent = AmbientAkSoundComponent_0

	Begin Object Class=KFWeaponAmbientEchoHandler Name=WeaponAmbientEchoHandler_0 Archetype = KFWeaponAmbientEchoHandler'KFGame.Default__KFPawn:WeaponAmbientEchoHandler_0'
	End Object
	WeaponAmbientEchoHandler = KFWeaponAmbientEchoHandler'Default__ST_Turret_Base:WeaponAmbientEchoHandler_0'

	Begin Object Name=FootstepAkSoundComponent
		BoneName="Dummy"
		bStopWhenOwnerDestroyed = True
		bForceOcclusionUpdateInterval = True
	End Object
	FootstepAkComponent = FootstepAkSoundComponent

	Begin Object Name=DialogAkSoundComponent
		BoneName="Dummy"
		bStopWhenOwnerDestroyed = True
	End Object
	DialogAkComponent = DialogAkSoundComponent

	Begin Object Class=SkeletalMeshComponent Name=SkelMesh
		bUpdateSkelWhenNotRendered = False
		ReplacementPrimitive = None
		RBChannel = RBCC_GameplayPhysics
		CollideActors = True
		BlockZeroExtent = True
		LightingChannels = (bInitialized = True, Indoor = True, Outdoor = True)
		RBCollideWithChannels = (Default = True, GameplayPhysics = True, EffectPhysics = True, BlockingVolume = True)
		Translation = (X = 0.0, Y = 0.0, Z = -50.0)
		Scale = 2.5
	End Object
	Mesh = SkelMesh

	Begin Object Name=CollisionCylinder
		CollisionHeight = 50.0
		CollisionRadius = 30.0
		ReplacementPrimitive = None
		CollideActors = True
		BlockActors = True
		BlockZeroExtent = False
	End Object
	CylinderComponent = CollisionCylinder
	Components.Add(CollisionCylinder)

	Begin Object Name=Arrow
		ArrowColor = (B = 255, G = 200, R = 150, A = 255)
		bTreatAsASprite = True
		SpriteCategoryName="Pawns"
		ReplacementPrimitive = None
	End Object
	Components.Add(Arrow)

	Begin Object Name=KFPawnSkeletalMeshComponent
		MinDistFactorForKinematicUpdate = 0.2
		bSkipAllUpdateWhenPhysicsAsleep = True
		bIgnoreControllersWhenNotRendered = True
		bHasPhysicsAssetInstance = True
		bUpdateKinematicBonesFromAnimation = False
		bPerBoneMotionBlur = True
		bOverrideAttachmentOwnerVisibility = True
		bChartDistanceFactor = True
		ReplacementPrimitive = None
		RBChannel = RBCC_Pawn
		RBDominanceGroup = 20
		bOwnerNoSee = True
		bAcceptsDynamicDecals = True
		bUseOnePassLightingOnTranslucency = True
		CollideActors = True
		BlockZeroExtent = True
		BlockRigidBody = True
		RBCollideWithChannels = (Default = True, Pawn = True, Vehicle = True, BlockingVolume = True)
		Translation = (X = 0.0, Y = 0.0, Z = -86.0)
		ScriptRigidBodyCollisionThreshold = 200.0
		PerObjectShadowCullDistance = 2500.0
		bAllowPerObjectShadows = True
		TickGroup = TG_DuringAsyncWork
	End Object
	Components.Add(KFPawnSkeletalMeshComponent)

	Components.Add(AmbientAkSoundComponent_0)
	Components.Add(AmbientAkSoundComponent_1)
	Components.Add(FootstepAkSoundComponent)
	Components.Add(DialogAkSoundComponent)
	Components.Add(SkelMesh)
	Physics = PHYS_Falling
	CollisionComponent = CollisionCylinder
}
