//Main Turret object class extends pawn, but notably not _Monster or _Human
Class ST_Turret_Base extends KFPawn
	config(SentryRedux)
	dependson(ST_Upgrades_Base);

enum FireTypeEnums // Used to easily access 
{
	EPrimaryFire,
	ESecondaryFire,
	ESpecialFire,

	ENumFireTypes // Used as int to cycle through fire types
};

var ST_Upgrades_Base UpgradesObj;
var class<ST_Upgrades_Base> UpgradesClass;

var transient ST_Overlay LocalOverlay;
var transient float ScanLocTimer, BuildTimer, NextTakeHitSound, NextFireSoundTime;
var transient bool bRecentlyBuilt, bIsScanning, bLeftScanned, bAlterFired, bAltMissileFired;
var transient int TempDamage;
var transient class<DamageType> TempDamageType;

var int SentryWorth, IntSightRadius;
var repnotify Actor ViewFocusActor;
var repnotify bool bFiringMode, bIsPendingFireMode, bWasSold;
var repnotify byte FireCounter[3];

var config int BuildCost, MissileSpeed, HealthLostNoOwner;

var SkelControlLookAt YawControl, PitchControl;
var PlayerController OwnerController;
var ST_Trigger_Base ActiveTrigger;
var vector ScanLocation, DesScanLocation;
var vector RepHitLocation;

// You cant replicate dynamic arrays easily - Using static arrays instead
// This limits us to 3 (or some arbitrary integer) integrated weapons per turret
var int AmmoCount[3], MaxAmmoCount[3], Damage[3];
var class<KFDamageType> DamageTypes[3];
var float AccuracyMod, TurnRadius, RoF, RefundMultiplier;
var AnimNodeSlot AnimationNode, UpperAnimNode;

var KFMuzzleFlash MuzzleFlash[4];

// SOUND
var SoundCue FiringSounds[3];
var SoundCue EmptySounds[3];
var SoundCue ScanningSound;
var SoundCue DamageTakenSound;
var SoundCue DieingSound;
var float NextFiringTime[3];

// REPLICATION
replication
{
	if(bNetDirty)
		bWasSold, ViewFocusActor, bFiringMode, RepHitLocation, SentryWorth, bRecentlyBuilt, FireCounter, AmmoCount, bIsPendingFireMode, OwnerController;
}

simulated event ReplicatedEvent(name VarName)
{
	switch(VarName)
	{
	case 'ViewFocusActor':
		SetViewFocus(ViewFocusActor);
		break;
	case 'bFiringMode':
		TurretSetFiring(bFiringMode);
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}

// FUNCTIONS
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		AddHUDOverlay();
	}

	if(WorldInfo.NetMode != NM_Client)
	{
		ActiveTrigger = Spawn(class'ST_Trigger_Base');
		ActiveTrigger.TurretOwner = Self;
		ActiveTrigger.SetBase(Self); // I believe this is automatically replicated to proxy-actors, worst case may need to use replciated event to trigger setbase() on client

		UpgradesObj = Spawn(UpgradesClass, Self);
		UpgradesObj.SetTurretOwner(Self);

		if(Controller == None)
			SpawnDefaultController();
	}

	SentryWorth = BuildCost;
}

simulated function InitBuild()
{
	// Reset skeletal mesh to default orientation
	SetViewFocus(None);

	// Stop shooting / shooting animation
	if(bFiringMode || bIsPendingFireMode)
		TurretSetFiring(false,true);

	// Stop the scanning animation
	if(bIsScanning)
		EndScanning();

	PreBuildAnimation(); // TODO: is there any optimization when using events instead of functions?
	// Fetch the build animation length in seconds then queue PostBuildAnimation() when it finishes
	BuildTimer = FClamp(AnimationNode.PlayCustomAnim('Build',1.f,0.f,0.f,false,true),0.5,5.0f); // 5.0 max up from 3.0
	SetTimer(BuildTimer, false, 'PostBuildAnimation');

	// Play build animation on clients
	if( WorldInfo.NetMode != NM_DedicatedServer && UpperAnimNode!=None )
		UpperAnimNode.PlayCustomAnim('Build',1.f,0.f,0.f,false,true);
}

simulated function PreBuildAnimation()
{
	// Disable AI targeting during build animation
	if(Controller != None)
		Controller.GoToState('Disabled');
}

simulated function PostBuildAnimation()
{
	// Reenable AI targeting
	if(Controller != None)
		Controller.GoToState('WaitForEnemy');
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

	InitBuild();
}

simulated final function AddHUDOverlay()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if(PC == None)
		return;

	LocalOverlay = class'ST_Overlay'.Static.GetOverlay(PC);
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
		Health -= HealthLostNoOwner;
		if(Health <= 0)
			KilledBy(None);
	}
}

function SetTurretOwner(PlayerController Other)
{
	SetTimer(4, true, 'CheckUserConnected');
	OwnerController = Other;
	PlayerReplicationInfo = Other.PlayerReplicationInfo;
}

function AddAmmo(coerce byte Index, int Amount) // Intentionally cast Index to byte for faster overflow checking
{
	if(Index < 3)
		AmmoCount[Index] = Min(AmmoCount[Index] + Amount, MaxAmmoCount[Index]);
}

simulated function string GetInfo()
{
	local float F;

	F = float(Health) / float(HealthMax) * 100.f;
	return "Owner: "$(PlayerReplicationInfo!=None ? PlayerReplicationInfo.PlayerName : "None")$" ("$(Health<HealthMax ? Clamp(F,1,99) : 100)$"% HP)";
}

simulated function string GetName()
{
	return "Owner: "$(PlayerReplicationInfo!=None ? PlayerReplicationInfo.PlayerName : "None");
}

simulated function string GetHealth() //for overlay
{
	return "Health: " $ class'ST_StaticHelper'.static.FormatPercent(Health, HealthMax);
}

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

simulated function string GetOwnerName()
{
	return (PlayerReplicationInfo != None ? PlayerReplicationInfo.PlayerName : "None");
}

simulated function SetViewFocus(Actor Other)
{
	ViewFocusActor = Other;
	if(WorldInfo.NetMode == NM_DedicatedServer)
		return;

	// I'm gonne be honest: idk what this section really does because it looks really dumb and I didnt want to research it.
	// There must be a native way to do it instead
	if(Other == None && !bIsScanning)
	{
		YawControl.SetSkelControlStrength(0.0f, 0.15f);
		if(PitchControl != None)
		{
			PitchControl.SetSkelControlStrength(0.0f, 0.15f);
		}
	}
	else
	{
		YawControl.SetSkelControlStrength(1.0f, 0.15f);
		if(PitchControl != None)
		{
			PitchControl.SetSkelControlStrength(1.0f, 0.15f);
		}
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
			User.PlayerReplicationInfo.Score += (SentryWorth * RefundMultiplier);
		
		KilledBy(None);
		return true;
	}

	else if(PlayerController(User) != None)
		PlayerController(User).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 5);
	return false;
}

simulated function TurretSetFiring(bool bFire, optional bool bInstant)
{
	bFiringMode = bFire;
	
	if(bFire)
	{
		if(WorldInfo.NetMode != NM_Client)
		{
			if(NextMissileTimer < WorldInfo.TimeSeconds)
				NextMissileTimer = WorldInfo.TimeSeconds + FRand() * 2.0f;
		}
		FireShot();
		
	}
	else
	{
		bIsPendingFireMode = false;
		FireCounter[0] = 0;
		ClearTimer('DelayedStartFire');
		ClearTimer('FireShot');
		
		if(WorldInfo.NetMode != NM_DedicatedServer && !bInstant)
		{
			ScanLocation = vector(Rotation);
			DesScanLocation = ScanLocation;
			AnimationNode.StopCustomAnim(0.05f);
			bIsScanning = true;
			SetViewFocus(ViewFocusActor);
			SetTimer(0.2f, false, 'ScanSound');
			SetTimer(6.0f, false, 'EndScanning');
		}
	}
}
simulated function ScanSound()
{
	if(ScanningSound == None)
		return;

	PlaySoundBase(ScanningSound, true);
	SetTimer(ScanningSound.GetCueDuration(), false, 'ScanSound');
}
simulated function EndScanning()
{
	bIsScanning = false;
	SetViewFocus(ViewFocusActor);
}

simulated function FirePrimary()
{
	// More efficient to do this here than to do it on a timer
	if(!Controller.CheckEnemyState())
		return;

	if(AmmoCount[0] <= 0)
	{
		if(WorldInfo.NetMode != NM_DedicatedServer)
			PlayOutOfAmmo();

		if(!bIsPendingFireMode)
		{
			bFiringMode = false;
			bIsPendingFireMode = true;
		}
		return;
	}
	else if(bIsPendingFireMode)
	{
		bFiringMode = true;
		bIsPendingFireMode = false;
	}

	if(WorldInfo.NetMode != NM_Client)
		--AmmoCount[0];

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		AnimationNode.PlayCustomAnim('Fire', 1.0f, 0.0f, 0.0f, false, true);
		if(NextFireSoundTime < WorldInfo.TimeSeconds)
		{
			NextFireSoundTime = WorldInfo.TimeSeconds + 0.15f;
			PlaySoundBase(FiringSounds[EPrimaryFire], true);
		}
	}
}
simulated function FireSecondary()
{
}
simulated function FireSpecial()
{
}

function CheckFireMissile()
{
	local Pawn T;
	local KFPawn P;
	local int HP;
	local rotator R;
	local vector Start;
	local ST_Proj_Missile Proj;
	
	T = Controller.Enemy;
	if(T == None)
		return;
	
	foreach WorldInfo.AllPawns(class'KFPawn', P, T.Location, 600.0f)
	{
		if(P == T || FastTrace(P.Location, T.Location))
			HP += (200 + P.Health);
	}
	
	if(HP > 800)
	{
		NextMissileTimer = WorldInfo.TimeSeconds + 3.8f;
		if(++FireCounter[0] > 250)
			FireCounter[0] = 1;
		if(WorldInfo.NetMode != NM_DedicatedServer)
			MakeFireMissileFX();
		
		// Fire proj itself.
		Start = Location + vect(0, 0, 122.0f); // Offset to put missile outside the turrets collision
		R = Controller.GetAdjustedAimFor(None, Start);
		Proj = Spawn(class'ST_Proj_Missile', , , Start, R);
		if(Proj != None)
		{
			if(UpgradesObj.HasUpgrade(EUpHomingMissiles))
				Proj.AimTarget = T;
			Proj.Damage = Damage[1];
			Proj.ExplosionTemplate.Damage = Damage[1];
			Proj.Init(vector(R));
			Proj.InstigatorController = OwnerController != None ? OwnerController : Controller;
			Proj.Speed = MissileSpeed;
		}
		 --AmmoCount[1];
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

simulated final function vector GetTraceStart()
{
	return Location + (UpgradesObj.TurretLevel == 0 ? vect(0, 0, 38.0f) : vect(0, 0, 77.0f));
}

final function bool CanSeeSpot(vector P)
{
	return (Normal(P - Location) Dot vector(Rotation)) > TurnRadius;
}

function vector GetAimPos(vector CamLoc, Pawn TPawn)
{
	local vector			HitLocation, HitNormal;
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;
	local vector                HeadLocation, TorsoLocation, PelvisLocation;

	// if bHeadhunter upgrade Check to see if we can hit the head
	if(UpgradesObj.HasUpgrade(EUpHeadshots))
	{
		HeadLocation = TPawn.Mesh.GetBoneLocation(HeadBoneName);
		HitActor = TPawn.Trace(HitLocation, HitNormal, HeadLocation, CamLoc, TRUE, vect(0,0,0), HitInfo, TRACEFLAG_Bullet);
		if( HitActor == none || HitActor == Self )
		{
			//`log("Autotarget - found head");
			return HeadLocation + (vect(0,0,-10.0));
		}
	}
	// Try for the torso
	TorsoLocation = TPawn.Mesh.GetBoneLocation(TorsoBoneName);
	HitActor = TPawn.Trace(HitLocation, HitNormal, TorsoLocation, CamLoc, TRUE, vect(0,0,0), HitInfo, TRACEFLAG_Bullet);
	if( HitActor == none || HitActor == Self)
	{
		return TorsoLocation;
	}
	// Try for the pelvis
	PelvisLocation = TPawn.Mesh.GetBoneLocation(PelvisBoneName);
	HitActor = TPawn.Trace(HitLocation, HitNormal, PelvisLocation, CamLoc, TRUE, vect(0,0,0), HitInfo, TRACEFLAG_Bullet);
	if( HitActor == none || HitActor == Self)
	{
		//`log("Autotarget - found pelvis");
		return PelvisLocation;
	}
	//`log("Autotarget - found noting - returning location");
	return Location + BaseEyeHeight * vect(0,0,0.5f);
}

simulated function FireBullet()
{
	local vector Start, End, Dir, HL, HN;
	local Actor A;
	local Pawn E;
	local TraceHitInfo H;
	local array<ImpactInfo> IL;
	local int HitZoneIndex;

	Start = GetTraceStart();
	if(WorldInfo.NetMode != NM_Client)
	{
		E = Controller != None ? Controller.Enemy : None;
		if(E != None && CanSeeSpot(E.Location))
		{
			if(ViewFocusActor != E)
				SetViewFocus(E);
			RepHitLocation = GetAimPos(Start, E);
		}
		else RepHitLocation = Location + vector(Rotation) * 2000.0f;
	}
	else if(RepHitLocation == vect(0, 0, 0))
		RepHitLocation = Location + vector(Rotation) * 2000.0f;

	Dir = Normal(RepHitLocation - Start);
	Dir = VRandCone(Dir, AccuracyMod); // Official way, should be faster. Angle is in radians

	End = Start + Dir * 10000.0f;
	foreach TraceActors(class'Actor', A, HL, HN, End, Start, , H)
	{
		if(A.bBlockActors || A.bProjTarget)
		{
			if(Pawn(A) != None)
			{
				if(Pawn(A).IsSameTeam(Self))
					continue;
				// TODO: Is there a faster trace function?
				if(KFPawn(A) != None && A.TraceAllPhysicsAssetInteractions(Pawn(A).Mesh, End, Start, IL, , true) && IL.Length > 0) // Try to trace for hitzone info.
				{
					H = IL[0].HitInfo;
				}
			}
			break;
		}
	}

	// If trace hit an actor on other team
	if(A != None)
	{
		// Set up and run damage modification on both client and server
		TempDamage = Damage[0];
		TempDamageType = DamageTypes[0];
		HitZoneIndex = HitZones.Find('ZoneName', H.BoneName);
		UpgradesObj.ModifyDamageGiven(TempDamage, A, TempDamageType, HitZoneIndex);

		if(WorldInfo.NetMode != NM_Client)
		{
			Controller.bIsPlayer = false;

			A.TakeDamage(TempDamage, (OwnerController != None ? OwnerController : Controller), HL, Dir * 10000.f, TempDamageType, H, Self);
			if(Controller != None) // Enemy may have exploded and killed the turret. 
				Controller.bIsPlayer = true;
			if(OwnerController != None && Pawn(A) != None && Pawn(A).Controller != None)
				Pawn(A).Controller.NotifyTakeHit(Controller, HL, TempDamage, TempDamageType, Dir); // Make enemy AI aggro the turret
		}
		else A.TakeDamage(TempDamage, Controller, HL, Dir * 10000.f, TempDamageType, H, Self);
	}
	else HL = End;

	// Client side graphical effects
	if(WorldInfo.NetMode != NM_DedicatedServer)
		DrawImpact(A, HL, HN);
}

simulated function FireProjectile() // Pass in int weaponindex and use for asset indexes
{
}

simulated function DrawImpact(Actor A, vector HitLocation, vector HitNormal)
{
	local ParticleSystemComponent E;
	local vector Start, Dir;
	local float Dist;
	local byte i;
	local name M;
	
	bAlterFired = !bAlterFired;
	if(UpgradesObj.TurretLevel == 0 || bAlterFired)
	{
		M = 'Muz';
		i = 0;
	}
	else
	{
		M = 'Muz2';
		i = 1;
	}

	if (MuzzleFlash[i] == None)
	{
		// This implies the muzzle flash is the same for both indexes. Why use an array?
		MuzzleFlash[i] = new(self) Class'KFMuzzleFlash'(KFMuzzleFlash'WEP_AA12_ARCH.Wep_AA12Shotgun_MuzzleFlash_3P');
		MuzzleFlash[i].AttachMuzzleFlash(Mesh, M, M);
		MuzzleFlash[i].MuzzleFlash.PSC.SetScale(2.5f);
	}
	MuzzleFlash[i].CauseMuzzleFlash(0);
	
	if(A != None)
	{
		KFImpactEffectManager(WorldInfo.MyImpactEffectManager).PlayImpactEffects(HitLocation, self, HitNormal, Class'KFProj_Bullet_LazerCutter'.Default.ImpactEffects);
	}

	Mesh.GetSocketWorldLocationAndRotation(M, Start);
	Dir = HitLocation - Start;
	Dist = VSize(Dir);
	
	if(Dist > 300.0f)
	{
		Dist = fMin((Dist - 100.0f) / 8000.0f, 1.0f);
		if(Dist > 0.0f) // Dont think this does anything based on above logic
		{
			E = WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'FX_Projectile_EMIT.FX_Common_Tracer_Instant', Start, rotator(Dir));
			E.SetScale(2);
			E.SetVectorParameter('Tracer_Velocity', vect(4000, 0, 0));
			E.SetFloatParameter('Tracer_Lifetime', Dist);
		}
	}
}

simulated function KFSkinTypeEffects GetHitZoneSkinTypeEffects(int HitZoneIdx)
{
	return KFSkinTypeEffects'FX_Impacts_ARCH.SkinTypes.Metal';
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	return Super.Died(Killer, DamageType, HitLocation);
}

simulated function Destroyed()
{
	local ST_SentryNetwork SN;

	if(WorldInfo.NetMode != NM_Client)
	{
		SN = class'ST_SentryNetwork'.static.GetNetwork(OwnerController); // Use the sentry network to notify the player locally to decrease the turret count
		if(SN != none)
			SN.DecrementTurretCount();
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
	if(InstigatedBy != None && InstigatedBy.GetTeamNum() == GetTeamNum())
		return;
	Super.TakeDamage(InDamage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

function AddVelocity(vector NewVelocity, vector HitLocation, class<DamageType> damageType, optional TraceHitInfo HitInfo);

function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	UpgradesObj.ModifyDamageTaken(InDamage, DamageType, InstigatedBy);
	Super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);
}

defaultproperties
{
	bWasSold = false

	UpgradesClass = class'ST_Upgrades_Base'

	Mass = 5500.000000
	BaseEyeHeight = 70.000000
	EyeHeight = 70.000000
	Health = 350 // Immediatly overwritten by config, ensures turret isnt spawnerd with 0 health
	HealthMax = 350 // Immediatly overwritten by config, ensures turret isnt spawnerd with 0 health
	ControllerClass = Class'ST_AI_Base'
	RefundMultiplier = 1.0f

	DamageTypes(0) = class'KFDT_Ballistic'

	Begin Object Name=ThirdPersonHead0
		ReplacementPrimitive = None
		bAcceptsDynamicDecals = True
	End Object
	ThirdPersonHeadMeshComponent = ThirdPersonHead0

	Begin Object Class=KFAfflictionManager Name=Afflictions_0 Archetype = KFAfflictionManager'KFGame.Default__KFPawn:Afflictions_0'
		FireFullyCharredDuration = 2.500000
		FireCharPercentThreshhold = 0.250000
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
		Translation = (X = 0.000000, Y = 0.000000, Z = -50.000000)
		Scale = 2.500000
	End Object
	Mesh = SkelMesh

	Begin Object Name=CollisionCylinder
		CollisionHeight = 50.000000
		CollisionRadius = 30.000000
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
		MinDistFactorForKinematicUpdate = 0.200000
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
		Translation = (X = 0.000000, Y = 0.000000, Z = -86.000000)
		ScriptRigidBodyCollisionThreshold = 200.000000
		PerObjectShadowCullDistance = 2500.000000
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
