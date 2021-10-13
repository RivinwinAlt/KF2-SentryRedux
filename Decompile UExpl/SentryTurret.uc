Class SentryTurret extends KFPawn
	config(SentryTurret);

var transient SentryMainRep ContentRef;
var transient SentryOverlay LocalOverlay;

var float AccurancyMod;
var AnimNodeSlot AnimationNode,UpperAnimNode;
var SkelControlLookAt YawControl,PitchControl;
var Controller OwnerController;
var SentryWeapon ActiveOwnerWeapon;
var repnotify int SentryWorth;
var SentryTrigger ActiveTrigger;
var repnotify byte PowerLevel;
var transient byte AutoRepairState;
var transient array<SentryUI_Network> CurrentUsers;

var SpotLightComponent TurretSpotLight;
var PointLightComponent TurretRedLight;

var int AmmoLevel[2];

const MAX_TURRET_LEVELS=3;

const ETU_IronSightA=0;
const ETU_IronSightB=1;
const ETU_EagleEyeA=2;
const ETU_EagleEyeB=3;
const ETU_Headshots=4;
const ETU_HomingMissiles=5;
const ETU_AutoRepair=6;
const ETU_AmmoSMG=7;
const ETU_AmmoSMGBig=8;
const ETU_AmmoMissiles=9;
const ETU_AmmoMissilesBig=10;
const ETU_AmmoSMGMax=11;
const ETU_AmmoMissilesMax=12;
const ETU_MAXUPGRADES=13;

struct FTurretLevel
{
	var Texture2D Icon;
	var float RoF;
	var PlayerReplicationInfo Buyer;
	var string UIName;
};
var FTurretLevel Levels[MAX_TURRET_LEVELS];
var FTurretLevel Upgrades[ETU_MAXUPGRADES];
var string UpgradeNames[ETU_MAXUPGRADES];

// Server settings.
var config byte MaxTurretsPerUser,MapMaxTurrets,HealthRegenRate;
var config int HealPerHit,MissileHitDamage;
var config float MinPlacementDistance;
var config int MaxAmmoCount[2];

struct FTurretLevelCfg
{
	var config int Cost,Damage,Health;
};
var config FTurretLevelCfg LevelCfgs[MAX_TURRET_LEVELS];

var config int UpgradeCosts[ETU_MAXUPGRADES];
var config int ConfigVersion;

/** A muzzle flash instance */
var KFMuzzleFlash MuzzleFlash[4];

var vector ScanLocation,DesScanLocation;
var transient float ScanLocTimer,BuildTimer,NextMissileTimer,NextTakeHitSound,NextFireSoundTime;

var repnotify byte CannonFireCounter,AcquiredUpgrades;
var vector RepHitLocation;
var repnotify Actor ViewFocusActor;
var repnotify bool bFiringMode,bIsPendingFireMode;
var transient bool bIsScanning,bLeftScanned,bRecentlyBuilt,bAlterFired,bAltMissileFired,bHeadHunter,bHasAutoRepair;
var bool bIsUserCreated;

replication
{
	// Variables the server should send ALL clients.
	if( true )
		ViewFocusActor,bFiringMode,RepHitLocation,PowerLevel,SentryWorth,bRecentlyBuilt,CannonFireCounter,AcquiredUpgrades,AmmoLevel,MaxAmmoCount,bIsPendingFireMode;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	ContentRef = class'SentryMainRep'.Static.FindContentRep(WorldInfo);
	if( ContentRef!=None )
		InitDisplay();
	if( WorldInfo.NetMode!=NM_DedicatedServer )
		AddHUDOverlay();
	if( WorldInfo.NetMode!=NM_Client && !bDeleteMe )
	{
		AmmoLevel[0] = MaxAmmoCount[0]/10;
		AmmoLevel[1] = MaxAmmoCount[1]/10;
		bRecentlyBuilt = true;
		SentryWorth = LevelCfgs[0].Cost;
		Health = LevelCfgs[0].Health;
		HealthMax = LevelCfgs[0].Health;
		if( Controller==None )
			SpawnDefaultController();
	}
	
	if( ActiveTrigger==None )
	{
		ActiveTrigger = Spawn(class'SentryTrigger');
		ActiveTrigger.TurretOwner = Self;
		ActiveTrigger.SetBase(Self);
	}


	SetTimer(0.001,false,'CheckBuilt');
}
simulated function CheckBuilt()
{
	ClearTimer('CheckBuilt');
	ClearTimer('UnsetBuilt');

	if( WorldInfo.NetMode!=NM_Client )
		bRecentlyBuilt = true;
	if( bRecentlyBuilt )
	{
		SetViewFocus(None);
		if( bFiringMode || bIsPendingFireMode )
			TurretSetFiring(false,true);
		if( bIsScanning )
			EndScanning();
		if( Controller!=None )
			Controller.GoToState('WaitForEnemy');

		BuildTimer = WorldInfo.TimeSeconds + FClamp(AnimationNode.PlayCustomAnim('Build',1.f,0.f,0.f,false,true),0.5,3.f);
		if( WorldInfo.NetMode!=NM_DedicatedServer && UpperAnimNode!=None )
			UpperAnimNode.PlayCustomAnim('Build',1.f,0.f,0.f,false,true);
		if( WorldInfo.NetMode!=NM_Client )
			SetTimer(0.5,false,'UnsetBuilt');
	}
}
function UnsetBuilt()
{
	bRecentlyBuilt = false;
}

static final function UpdateConfig()
{
	if( Default.ConfigVersion!=1 )
	{
		Default.MaxTurretsPerUser = 3;
		Default.MapMaxTurrets = 12;
		Default.MinPlacementDistance = 250;
		Default.HealPerHit = 35;
		Default.MissileHitDamage = 1500;
		Default.HealthRegenRate = 10;
		Default.LevelCfgs[0].Cost = 2000;
		Default.LevelCfgs[0].Damage = 10;
		Default.LevelCfgs[0].Health = 350;
		Default.LevelCfgs[1].Cost = 1500;
		Default.LevelCfgs[1].Damage = 11;
		Default.LevelCfgs[1].Health = 400;
		Default.LevelCfgs[2].Cost = 2500;
		Default.LevelCfgs[2].Damage = 13;
		Default.LevelCfgs[2].Health = 600;
		Default.UpgradeCosts[ETU_IronSightA] = 100;
		Default.UpgradeCosts[ETU_IronSightB] = 200;
		Default.UpgradeCosts[ETU_EagleEyeA] = 250;
		Default.UpgradeCosts[ETU_EagleEyeB] = 450;
		Default.UpgradeCosts[ETU_Headshots] = 500;
		Default.UpgradeCosts[ETU_HomingMissiles] = 400;
		Default.UpgradeCosts[ETU_AutoRepair] = 650;
		Default.UpgradeCosts[ETU_AmmoSMG] = 45;
		Default.UpgradeCosts[ETU_AmmoSMGBig] = 200;
		Default.UpgradeCosts[ETU_AmmoSMGMax] = 2000;
		Default.UpgradeCosts[ETU_AmmoMissiles] = 100;
		Default.UpgradeCosts[ETU_AmmoMissilesBig] = 450;
		Default.MaxAmmoCount[0] = 2000;
		Default.MaxAmmoCount[1] = 50;
		Default.ConfigVersion = 1;
		StaticSaveConfig();
	}
}

simulated final function InitDisplay()
{
	UpdateDisplayMesh();
}
simulated final function UpdateDisplayMesh()
{
	RemoveMuzzles();

	AnimationNode = None;
	UpperAnimNode = None;

	if( WorldInfo.NetMode!=NM_DedicatedServer && Mesh.SkeletalMesh!=None )
	{
		Mesh.DetachComponent(TurretSpotLight);
		Mesh.DetachComponent(TurretRedLight);
	}

	Mesh.SetSkeletalMesh(ContentRef.TurretArch[PowerLevel].CharacterMesh);
	Mesh.AnimSets = ContentRef.TurretArch[PowerLevel].AnimSets;
	Mesh.SetAnimTreeTemplate(ContentRef.TurretArch[PowerLevel].AnimTreeTemplate);
	Mesh.SetPhysicsAsset(ContentRef.TurretArch[PowerLevel].PhysAsset);

	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		Mesh.AttachComponentToSocket(TurretSpotLight,'SpotLight');
		Mesh.AttachComponentToSocket(TurretRedLight,'SpotLight');

		switch( PowerLevel )
		{
		case 0:
			Mesh.SetMaterial(0,ContentRef.TurSkins[0]);
			break;
		case 1:
			Mesh.SetMaterial(0,ContentRef.TurSkins[0]);
			Mesh.SetMaterial(1,ContentRef.TurSkins[1]);
			break;
		case 2:
			Mesh.SetMaterial(0,ContentRef.TurSkins[2]);
			Mesh.SetMaterial(1,ContentRef.TurSkins[0]);
			Mesh.SetMaterial(2,ContentRef.TurSkins[1]);
			break;
		}
	}
}
simulated final function SoundCue GrabCue( byte Index )
{
	return ContentRef!=None ? SoundCue(ContentRef.ObjRef.ReferencedObjects[Index]) : None;
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	AnimationNode = AnimNodeSlot(SkelComp.FindAnimNode('AnimBody'));
	if( PowerLevel==2 )
		UpperAnimNode = AnimNodeSlot(SkelComp.FindAnimNode('Cannon'));
	YawControl = SkelControlLookAt(SkelComp.FindSkelControl('YawBone'));
	PitchControl = SkelControlLookAt(SkelComp.FindSkelControl('PitchBone'));

	Super(Pawn).PostInitAnimTree(SkelComp);
}

simulated event ReplicatedEvent( name VarName )
{
	switch( VarName )
	{
	case 'ViewFocusActor':
		SetViewFocus(ViewFocusActor);
		break;
	case 'bFiringMode':
		TurretSetFiring(bFiringMode);
		break;
	case 'PowerLevel':
		SetLevelUp();
		break;
	case 'AcquiredUpgrades':
		SetUpgrades();
	case 'SentryWorth':
		ClientStatUpdate(255);
		break;
	case 'CannonFireCounter':
		if( CannonFireCounter!=0 )
			MakeFireMissileFX();
		break;
	case 'bIsPendingFireMode':
		if( bIsPendingFireMode )
			PlayOutOfAmmo();
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}

simulated final function AddHUDOverlay()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if( PC==None )
		return;
	LocalOverlay = class'SentryOverlay'.Static.GetOverlay(PC);
	LocalOverlay.ActiveTurrets.AddItem(Self);
}

function CheckUserAlive() // Check if owner player disconnects from server.
{
	if( OwnerController==None && !FindNewOwner() )
		KilledBy(None);
}

final function bool FindNewOwner()
{
	local SentryUI_Network N;

	foreach CurrentUsers(N)
		if( N.PlayerOwner!=None && N.PlayerOwner.Pawn!=None && N.PlayerOwner.Pawn.IsAliveAndWell() )
		{
			SetTurretOwner(N.PlayerOwner);
			return true;
		}
	return false;
}
function SetTurretOwner( Controller Other, optional SentryWeapon W )
{
	SetTimer(4+FRand(),true,'CheckUserAlive');
	OwnerController = Other;
	PlayerReplicationInfo = Other.PlayerReplicationInfo;
	bIsUserCreated = true;
	
	// Increment owned turret count.
	ActiveOwnerWeapon = W!=None ? W : SentryWeapon(Other.Pawn.FindInventoryType(class'SentryWeapon'));
	if( ActiveOwnerWeapon!=None )
		++ActiveOwnerWeapon.NumTurrets;
}

simulated function string GetInfo()
{
	local float F;

	F = float(Health) / float(HealthMax) * 100.f;
	return "Owner: "$(PlayerReplicationInfo!=None ? PlayerReplicationInfo.PlayerName : "None")$" ("$(Health<HealthMax ? Clamp(F,1,99) : 100)$"% HP)";
}
simulated function string GetAmmoStatus()
{
	local string S;
	
	if( PowerLevel==2 )
		S = " - "$AmmoLevel[1]$"/"$MaxAmmoCount[1];
	return AmmoLevel[0]$"/"$MaxAmmoCount[0]$S;
}

simulated function string GetOwnerName()
{
	return (PlayerReplicationInfo!=None ? PlayerReplicationInfo.PlayerName : "Someone");
}

simulated function SetViewFocus( Actor Other )
{
	ViewFocusActor = Other;
	if( WorldInfo.NetMode==NM_DedicatedServer )
		return;

	if( Other==None && !bIsScanning )
	{
		YawControl.SetSkelControlStrength(0.f,0.15);
		if( PitchControl!=None )
		{
			PitchControl.SetSkelControlStrength(0.f,0.15);
		}
	}
	else
	{
		YawControl.SetSkelControlStrength(1.f,0.15);
		if( PitchControl!=None )
		{
			PitchControl.SetSkelControlStrength(1.f,0.15);
		}
	}
}

simulated function Tick( float Delta )
{
	if( WorldInfo.NetMode!=NM_DedicatedServer && Health>0 )
	{
		if( ViewFocusActor!=None )
		{
			YawControl.SetTargetLocation(ViewFocusActor.Location);
			YawControl.InterpolateTargetLocation(Delta);
			if( PitchControl!=None )
			{
				PitchControl.SetTargetLocation(ViewFocusActor.Location);
				PitchControl.InterpolateTargetLocation(Delta);
			}
		}
		else if( bIsScanning )
		{
			if( ScanLocTimer<WorldInfo.TimeSeconds )
				PickNextScanLocation();
			SetScanLocation();
			YawControl.InterpolateTargetLocation(Delta);
			if( PitchControl!=None )
				PitchControl.InterpolateTargetLocation(Delta);
		}
	}
}
simulated final function PickNextScanLocation()
{
	local vector X,Y,Z;
	
	ScanLocation = DesScanLocation;
	GetAxes(Rotation,X,Y,Z);
	DesScanLocation = Normal(X+(bLeftScanned ? Y : -Y)*0.325);
	bLeftScanned = !bLeftScanned;
	ScanLocTimer = WorldInfo.TimeSeconds+1.05f;
}
simulated final function SetScanLocation()
{
	local float T;
	local vector V;
	
	T = (ScanLocTimer-WorldInfo.TimeSeconds) / 1.05f;
	V = Location + (ScanLocation*T + DesScanLocation*(1.f-T)) * 5000.f;
	YawControl.SetTargetLocation(V);
	if( PitchControl!=None )
		PitchControl.SetTargetLocation(V);
}

function TryToSellTurret( Controller User )
{
	if( OwnerController==User )
	{
		if( User.PlayerReplicationInfo!=None )
			User.PlayerReplicationInfo.Score += (SentryWorth * 0.2);
		KilledBy(None);
	}
	else if( PlayerController(User)!=None )
		PlayerController(User).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 5 );
}

simulated function SetLevelUp()
{
	if( WorldInfo.NetMode!=NM_Client )
	{
		++PowerLevel;
		bRecentlyBuilt = true;
		HealthMax = LevelCfgs[PowerLevel].Health;
		Health = Min(Health,HealthMax);
		
		if( bHasAutoRepair && Health<HealthMax && AutoRepairState==0 )
		{
			AutoRepairState = 1;
			SetTimer(30,false,'AutoRepairTimer');
		}
	}
	else ClientStatUpdate(PowerLevel);
	
	UpdateDisplayMesh();
	SetTimer(0.001,false,'CheckBuilt');
}

// UPGRADES:
simulated final function bool HasUpgrade( byte Index )
{
	if( Index<MAX_TURRET_LEVELS )
		return (PowerLevel>=Index);
	Index -= MAX_TURRET_LEVELS;
	switch( Index )
	{
	case ETU_IronSightA:
		return (AcquiredUpgrades & 3)!=0;
	case ETU_IronSightB:
		return (AcquiredUpgrades & 2)!=0;
	case ETU_EagleEyeA:
		return HasUpgradeFlags(ETU_EagleEyeA);
	case ETU_EagleEyeB:
		return HasUpgradeFlags(ETU_EagleEyeB);
	case ETU_Headshots:
		return HasUpgradeFlags(ETU_Headshots);
	case ETU_HomingMissiles:
		return HasUpgradeFlags(ETU_HomingMissiles);
	case ETU_AutoRepair:
		return HasUpgradeFlags(ETU_AutoRepair);
	}
	return false;
}
simulated final function bool CanUpgrade( byte Index )
{
	if( Index<MAX_TURRET_LEVELS )
		return ((PowerLevel+1)==Index);
	Index -= MAX_TURRET_LEVELS;
	switch( Index )
	{
	case ETU_IronSightA:
		return (AcquiredUpgrades & 3)==0;
	case ETU_IronSightB:
		return (AcquiredUpgrades & 3)==1;
	case ETU_EagleEyeA:
		return !HasUpgradeFlags(ETU_EagleEyeA);
	case ETU_EagleEyeB:
		return HasUpgradeFlags(ETU_EagleEyeA) && !HasUpgradeFlags(ETU_EagleEyeB);
	case ETU_Headshots:
		return !HasUpgradeFlags(ETU_Headshots);
	case ETU_HomingMissiles:
		return PowerLevel==2 && !HasUpgradeFlags(ETU_HomingMissiles);
	case ETU_AutoRepair:
		return !HasUpgradeFlags(ETU_AutoRepair);
	case ETU_AmmoSMG:
	case ETU_AmmoSMGBig:
	
		return AmmoLevel[0]<MaxAmmoCount[0];
	case ETU_AmmoMissiles:
	case ETU_AmmoMissilesBig:
	
		return PowerLevel==2 && AmmoLevel[1]<MaxAmmoCount[1];
	}
	return false;
}

final function SetUpgradeFlags( byte Index )
{
	AcquiredUpgrades = AcquiredUpgrades | (1 << Index);
}
final function ClearUpgradeFlags( byte Index )
{
	AcquiredUpgrades = AcquiredUpgrades & ~(1 << Index);
}
simulated final function bool HasUpgradeFlags( byte Index )
{
	return (AcquiredUpgrades & (1 << Index))!=0;
}
final function ApplyUpgrade( byte Index )
{
	if( Index>=ETU_AmmoSMG )
	{
		switch( Index )
		{
		case ETU_AmmoSMG:
			AmmoLevel[0] = Min(AmmoLevel[0]+100,MaxAmmoCount[0]);
			break;
		case ETU_AmmoSMGBig:
			AmmoLevel[0] = Min(AmmoLevel[0]+500,MaxAmmoCount[0]);
			break;
		case ETU_AmmoMissiles:
			AmmoLevel[1] = Min(AmmoLevel[1]+10,MaxAmmoCount[1]);
			break;
		case ETU_AmmoMissilesBig:
			AmmoLevel[1] = Min(AmmoLevel[1]+50,MaxAmmoCount[1]);
			break;

		}
	}
	else
	{
		if( Index==ETU_IronSightB )
			ClearUpgradeFlags(ETU_IronSightA);
		SetUpgradeFlags(Index);
		SetUpgrades();
	}
	NotifyStatUpdate(MAX_TURRET_LEVELS+Index);
}

simulated final function SetUpgrades()
{
	if( HasUpgradeFlags(ETU_IronSightB) )
		AccurancyMod = 0.4f;
	else if( HasUpgradeFlags(ETU_IronSightA) )
		AccurancyMod = 0.7f;
	else AccurancyMod = 1.f;
	
	if( WorldInfo.NetMode!=NM_Client )
	{
		SightRadius = Default.SightRadius;
		if( HasUpgradeFlags(ETU_EagleEyeB) )
			SightRadius *= 2.f;
		else if( HasUpgradeFlags(ETU_EagleEyeA) )
			SightRadius *= 1.5f;
		
		bHeadHunter = HasUpgradeFlags(ETU_Headshots);
		bHasAutoRepair = HasUpgradeFlags(ETU_AutoRepair);
		
		if( bHasAutoRepair && AutoRepairState==0 && Health<HealthMax )
		{
			AutoRepairState = 1;
			SetTimer(30,false,'AutoRepairTimer');
		}
	}
}

final function NotifyStatUpdate( byte Index )
{
	local SentryUI_Network N;

	foreach CurrentUsers(N)
		N.StatUpdated(Index);
}
simulated final function ClientStatUpdate( byte Index )
{
	local SentryUI_Network N;
	
	foreach CurrentUsers(N)
		N.ClientStatUpdated(Index);
}

function DelayedStartFire()
{
	TurretSetFiring(true);
}
simulated function TurretSetFiring( bool bFire, optional bool bInstant )
{
	bFiringMode = bFire;
	
	if( bFire )
	{
		if( WorldInfo.NetMode!=NM_Client )
		{
			if( NextMissileTimer<WorldInfo.TimeSeconds ) // Sometimes delay missile firing (just so all turrets dont fire at same time).
				NextMissileTimer = WorldInfo.TimeSeconds+FRand()*2.f;
		}
		FireShot();
		SetTimer(Levels[PowerLevel].RoF,true,'FireShot');
	}
	else
	{
		bIsPendingFireMode = false;
		CannonFireCounter = 0;
		ClearTimer('DelayedStartFire');
		ClearTimer('FireShot');
		
		if( WorldInfo.NetMode!=NM_DedicatedServer && !bInstant )
		{
			ScanLocation = vector(Rotation);
			DesScanLocation = ScanLocation;
			AnimationNode.StopCustomAnim(0.05);
			bIsScanning = true;
			SetViewFocus(ViewFocusActor);
			SetTimer(0.2,false,'ScanSound');
			SetTimer(6.f,false,'EndScanning');
		}
	}
}
simulated function PlayOutOfAmmo()
{
	PlaySoundBase(GrabCue(13),true);
}

simulated function ScanSound()
{
	local SoundCue C;
	
	if( !bIsScanning || Health<=0 )
		return;
	if( PowerLevel==0 )
		C = GrabCue(5);
	else if( PowerLevel==1 )
		C = GrabCue(9);
	else C = GrabCue(10);
	if( C==None )
		return;

	PlaySoundBase(C,true);
	SetTimer(C.GetCueDuration(),false,'ScanSound');
}
simulated function EndScanning()
{
	bIsScanning = false;
	SetViewFocus(ViewFocusActor);
}

simulated function FireShot()
{
	if( WorldInfo.NetMode!=NM_Client )
	{
		if( PowerLevel==2 && NextMissileTimer<WorldInfo.TimeSeconds && AmmoLevel[1]>0 )
			CheckFireMissile();
		if( AmmoLevel[0]<=0 )
		{
			if( !bIsPendingFireMode )
			{
				bFiringMode = false;
				bIsPendingFireMode = true;
				if( WorldInfo.NetMode!=NM_DedicatedServer )
					PlayOutOfAmmo();
			}
			return;
		}
		else if( bIsPendingFireMode )
		{
			bFiringMode = true;
			bIsPendingFireMode = false;
		}
		--AmmoLevel[0];
	}
	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		AnimationNode.PlayCustomAnim('Fire',1.f,0.f,0.f,false,true);
		if( NextFireSoundTime<WorldInfo.TimeSeconds )
		{
			NextFireSoundTime = WorldInfo.TimeSeconds+0.15;
			if( PowerLevel==0 )
				PlaySoundBase(GrabCue(6),true);
			else if( PowerLevel==1 )
				PlaySoundBase(GrabCue(7),true);
			else PlaySoundBase(GrabCue(8),true);
		}
	}
	TraceFire();
}

function CheckFireMissile()
{
	local Pawn T;
	local KFPawn P;
	local int HP;
	local rotator R;
	local vector Start;
	local KFProj_Missile_Sentry Proj;
	
	T = Controller.Enemy;
	if( T==None )
		return;
	
	foreach WorldInfo.AllPawns(class'KFPawn',P,T.Location,600.f)
	{
		if( P==T || FastTrace(P.Location,T.Location) )
			HP += (200 + P.Health);
	}
	
	if( HP>800 )
	{
		NextMissileTimer = WorldInfo.TimeSeconds+3.8f;
		if( ++CannonFireCounter>250 )
			CannonFireCounter = 1;
		if( WorldInfo.NetMode!=NM_DedicatedServer )
			MakeFireMissileFX();
		
		// Fire proj itself.
		Start = Location + vect(0,0,122.f);
		R = Controller.GetAdjustedAimFor(None,Start);
		Proj = Spawn(class'KFProj_Missile_Sentry',,,Start,R);
		if( Proj!=None )
		{
			if( HasUpgradeFlags(ETU_HomingMissiles) )
				Proj.AimTarget = T;
			Proj.Damage = MissileHitDamage;
			Proj.ExplosionTemplate.Damage = MissileHitDamage;
			Proj.Init(vector(R));
			Proj.InstigatorController = OwnerController!=None ? OwnerController : Controller;
		}
		--AmmoLevel[1];
	}
}

simulated function MakeFireMissileFX()
{
	local byte i;
	local name M;

	bAltMissileFired = !bAltMissileFired;
	i = 2+byte(bAltMissileFired);
	M = bAltMissileFired ? 'RoMuz' : 'RoMuz2';
	UpperAnimNode.PlayCustomAnim('FireRocket',1.f,0.f,0.f,false,true);
	
	if (MuzzleFlash[i] == None )
	{
		MuzzleFlash[i] = new(self) Class'KFMuzzleFlash'(KFMuzzleFlash'WEP_AA12_ARCH.Wep_AA12Shotgun_MuzzleFlash_3P');
		MuzzleFlash[i].AttachMuzzleFlash(Mesh,M,M);
		MuzzleFlash[i].MuzzleFlash.PSC.SetScale(3.5);
	}
	MuzzleFlash[i].CauseMuzzleFlash(0);
}

simulated final function vector GetTraceStart()
{
	return Location+(PowerLevel==0 ? vect(0,0,38.f) : vect(0,0,77.f));
}

final function vector GetAimPos( vector Start, Pawn Other )
{
	local KFPawn P;

	if( bHeadHunter )
	{
		P = KFPawn(Other);
		if( P!=None )
			return P.GetAutoLookAtLocation(Start,Self);
	}
	return Other.Location + (Other.BaseEyeHeight * vect(0,0,0.25f));
}

final function bool CanSeeSpot( vector P )
{
	return (Normal(P-Location) Dot vector(Rotation))>0.6;
}

simulated function TraceFire()
{
	local vector Start,End,Dir,HL,HN;
	local Actor A;
	local Pawn E;
	local TraceHitInfo H;
	local array<ImpactInfo> IL;

	Start = GetTraceStart();
	if( WorldInfo.NetMode!=NM_Client )
	{
		E = Controller!=None ? Controller.Enemy : None;
		if( E!=None && CanSeeSpot(E.Location) )
		{
			if( ViewFocusActor!=E )
				SetViewFocus(E);
			RepHitLocation = GetAimPos(Start,E);
		}
		else RepHitLocation = Location+vector(Rotation)*2000.f;
	}
	else if( RepHitLocation==vect(0,0,0) )
		RepHitLocation = Location+vector(Rotation)*2000.f;

	Dir = Normal(RepHitLocation-Start);
	Dir = Normal(Dir+VRand()*(0.075*AccurancyMod*FRand()));
	End = Start + Dir*10000.f;
	foreach TraceActors(class'Actor',A,HL,HN,End,Start,,H)
	{
		if( A.bBlockActors || A.bProjTarget )
		{
			if( Pawn(A)!=None )
			{
				if( Pawn(A).IsSameTeam(Self) )
					continue;
				if( KFPawn(A)!=None && A.TraceAllPhysicsAssetInteractions(Pawn(A).Mesh,End,Start,IL,,true) && IL.Length>0 ) // Try to trace for hitzone info.
				{
					H = IL[0].HitInfo;
				}
			}
			break;
		}
	}

	// Deal damage.
	if( A!=None )
	{
		if( WorldInfo.NetMode!=NM_Client )
		{
			Controller.bIsPlayer = false;
			A.TakeDamage(LevelCfgs[PowerLevel].Damage+Rand(4),(OwnerController!=None ? OwnerController : Controller),HL,Dir*10000.f,class'KFDT_Ballistic',H,Self);
			if( Controller!=None ) // Enemy may have exploded and killed the turret.
				Controller.bIsPlayer = true;
			if( OwnerController!=None && Pawn(A)!=None && Pawn(A).Controller!=None )
				Pawn(A).Controller.NotifyTakeHit(Controller,HL,14,class'KFDT_Ballistic',Dir); // Make enemy AI hate us and not just the turret owner.
		}
		else A.TakeDamage(14,Controller,HL,Dir*10000.f,class'KFDT_Ballistic',H,Self);
	}
	else HL = End;

	// Local FX
	if( WorldInfo.NetMode!=NM_DedicatedServer )
		DrawImpact(A,HL,HN);
}

simulated function DrawImpact( Actor A, vector HitLocation, vector HitNormal )
{
	local ParticleSystemComponent E;
	local vector Start,Dir;
	local float Dist;
	local byte i;
	local name M;
	
	bAlterFired = !bAlterFired;
	if( PowerLevel==0 || bAlterFired )
	{
		M = 'Muz';
		i = 0;
	}
	else
	{
		M = 'Muz2';
		i = 1;
	}

	if (MuzzleFlash[i] == None )
	{
		MuzzleFlash[i] = new(self) Class'KFMuzzleFlash'(KFMuzzleFlash'WEP_AA12_ARCH.Wep_AA12Shotgun_MuzzleFlash_3P');
		MuzzleFlash[i].AttachMuzzleFlash(Mesh,M,M);
		MuzzleFlash[i].MuzzleFlash.PSC.SetScale(2.5);
	}
	MuzzleFlash[i].CauseMuzzleFlash(0);
	
	if( A!=None )
	{
		KFImpactEffectManager(WorldInfo.MyImpactEffectManager).PlayImpactEffects(HitLocation, self, HitNormal, Class'KFProj_Bullet_LazerCutter'.Default.ImpactEffects);
	}

	Mesh.GetSocketWorldLocationAndRotation(M,Start);
	Dir = HitLocation-Start;
	Dist = VSize(Dir);
	
	if( Dist>300.f )
	{
		Dist = fMin( (Dist - 100.f) / 8000.f, 1.f );
		if( Dist > 0.f )
		{
			E = WorldInfo.MyEmitterPool.SpawnEmitter( ParticleSystem'FX_Projectile_EMIT.FX_Common_Tracer_Instant', Start, rotator(Dir) );
			E.SetScale(2);
			E.SetVectorParameter( 'Tracer_Velocity', vect(4000,0,0) );
			E.SetFloatParameter( 'Tracer_Lifetime', Dist );
		}
	}
}

simulated function KFSkinTypeEffects GetHitZoneSkinTypeEffects( int HitZoneIdx )
{
	return KFSkinTypeEffects'FX_Impacts_ARCH.SkinTypes.Metal';
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local int i;

	// Notify users of this.
	for( i=(CurrentUsers.Length-1); i>=0; --i )
		CurrentUsers[i].Destroy();

	if( PlayerController(OwnerController)!=None )
		PlayerController(OwnerController).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 4 );
	if( Controller!=None )
		Controller.bIsPlayer = false;
	if( ActiveOwnerWeapon!=None )
	{
		--ActiveOwnerWeapon.NumTurrets;
		ActiveOwnerWeapon = None;
	}
	if( ActiveTrigger!=None )
	{
		ActiveTrigger.Destroy();
		ActiveTrigger = None;
	}
	return Super.Died(Killer,DamageType,HitLocation);
}

simulated function Destroyed()
{
	if( ActiveOwnerWeapon!=None )
	{
		--ActiveOwnerWeapon.NumTurrets;
		ActiveOwnerWeapon = None;
	}
	if( LocalOverlay!=None )
		LocalOverlay.ActiveTurrets.RemoveItem(Self);
	RemoveMuzzles();
	if( ActiveTrigger!=None )
	{
		ActiveTrigger.Destroy();
		ActiveTrigger = None;
	}
	Super.Destroyed();
}

simulated final function RemoveMuzzles()
{
	local byte i;
	
	for( i=0; i<ArrayCount(MuzzleFlash); ++i )
		if (MuzzleFlash[i] != None)
		{
			MuzzleFlash[i].DetachMuzzleFlash(Mesh);
			MuzzleFlash[i] = None;
		}
}

simulated final function SetFloorOrientation( vector LandNormal )
{
	local vector X,Y,Z;
	local rotator R;

	R.Yaw = Rotation.Yaw;
	if( LandNormal.Z>0.997f || LandNormal.Z<=0.2f )
	{
		SetRotation(R);
		return;
	}

	// Fast dummy method for making it adjust to ground direction.
	GetAxes(R,X,Y,Z);
	X = Normal(X-LandNormal*(X Dot LandNormal));
	Y = Normal(Y-LandNormal*(Y Dot LandNormal));
	Z = (X Cross Y);
	SetRotation(OrthoRotation(X,Y,Z));
}

event Landed(vector HitNormal, Actor FloorActor)
{
	SetPhysics(PHYS_None);
	SetFloorOrientation(HitNormal);
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	Super.PlayDying(DamageType,HitLoc);
	
	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		PlaySoundBase(GrabCue(4),true);
		WorldInfo.MyEmitterPool.SpawnEmitter( ParticleSystem'WEP_3P_EMP_EMIT.FX_EMP_Grenade_Explosion', Location);
		WorldInfo.MyEmitterPool.SpawnEmitter( ParticleSystem'WEP_3P_MKII_EMIT.FX_MKII_Grenade_Explosion', Location);
	}
	if( ActiveTrigger!=None )
	{
		ActiveTrigger.Destroy();
		ActiveTrigger = None;
	}
}

function AutoRepairTimer()
{
	if( AutoRepairState==1 )
	{
		AutoRepairState = 2;
		SetTimer(1,true,'AutoRepairTimer');
	}
	Health = Min(Health+HealthRegenRate,HealthMax);
	if( Health>=HealthMax )
	{
		AutoRepairState = 0;
		ClearTimer('AutoRepairTimer');
	}
}

function PlayHit(float Damage, Controller InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum, TraceHitInfo HitInfo)
{
	if( Damage>0 && bHasAutoRepair && Health<HealthMax )
	{
		AutoRepairState = 1;
		SetTimer(30,false,'AutoRepairTimer');
	}
	if( Damage>5 && NextTakeHitSound<WorldInfo.TimeSeconds )
	{
		NextTakeHitSound = WorldInfo.TimeSeconds+0.5;
		PlaySoundBase(SoundCue'tf2sentry.Sounds.sentry_damage1_Cue');
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
event bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType, optional bool bCanRepairArmor=true, optional bool bMessageHealer=true)
{
    if( Amount>0 && IsAliveAndWell() && Health < HealthMax )
    {
		Amount = Min(Amount,HealthMax-Health);
		Health+=Amount;
		if( KFPlayerController(Healer)!=None )
			KFPlayerController(Healer).AddWeldPoints( Amount<<1 );
		return true;
    }
	return false;
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if( InstigatedBy!=None && (InstigatedBy==Controller || InstigatedBy.GetTeamNum()==GetTeamNum()) )
		return;
	Super.TakeDamage(Damage,InstigatedBy,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);
}

function AddVelocity( vector NewVelocity, vector HitLocation, class<DamageType> damageType, optional TraceHitInfo HitInfo );

function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	if( class<KFDT_Sonic>(DamageType)!=None )
		InDamage *= 0.1;
	Super.AdjustDamage(InDamage,Momentum,InstigatedBy,HitLocation,DamageType,HitInfo,DamageCauser);
}


// Decompiled with UE Explorer.
defaultproperties
{
    AccurancyMod=1.0
    begin object name=SpotLight1 class=SpotLightComponent
        OuterConeAngle=35.0
        Radius=2000.0
        FalloffExponent=3.0
        Brightness=1.750
        CastShadows=false
        CastStaticShadows=false
        CastDynamicShadows=false
        bCastCompositeShadow=false
        bCastPerObjectShadows=false
        LightingChannels=(Outdoor=true)
        MaxDrawDistance=3500.0
    object end
    // Reference: SpotLightComponent'Default__SentryTurret.SpotLight1'
    TurretSpotLight=SpotLight1
    begin object name=PointLightComponent1 class=PointLightComponent
        Radius=120.0
        Brightness=4.0
        LightColor=(R=255,G=0,B=255,A=255)
        CastShadows=false
        LightingChannels=(Outdoor=true)
        MaxBrightness=1.0
        AnimationType=2
        AnimationFrequency=1.0
    object end
    // Reference: PointLightComponent'Default__SentryTurret.PointLightComponent1'
    TurretRedLight=PointLightComponent1
    Levels[0]=(Icon=Texture2D'UI_LevelChevrons_TEX.UI_LevelChevron_Icon_01',RoF=0.30,Buyer=none,UIName="Level1")
    Levels[1]=(Icon=Texture2D'UI_LevelChevrons_TEX.UI_LevelChevron_Icon_02',RoF=0.1250,Buyer=none,UIName="Level2")
    Levels[2]=(Icon=Texture2D'UI_LevelChevrons_TEX.UI_LevelChevron_Icon_04',RoF=0.10,Buyer=none,UIName="Level3")
    Upgrades[0]=(Icon=Texture2D'UI_Award_PersonalMulti.UI_Award_PersonalMulti-Headshots',RoF=0.0,Buyer=none,UIName="IronSight1")
    Upgrades[1]=(Icon=Texture2D'UI_Award_PersonalSolo.UI_Award_PersonalSolo-Headshots',RoF=0.0,Buyer=none,UIName="IronSight2")
    Upgrades[2]=(Icon=Texture2D'UI_PerkTalent_TEX.commando.UI_Talents_Commando_Impact',RoF=0.0,Buyer=none,UIName="EagleEye1")
    Upgrades[3]=(Icon=Texture2D'UI_PerkTalent_TEX.commando.UI_Talents_Commando_AutoFire',RoF=0.0,Buyer=none,UIName="EagleEye2")
    Upgrades[4]=(Icon=Texture2D'UI_Award_Team.UI_Award_Team-Headshots',RoF=0.0,Buyer=none,UIName="Headshot")
    Upgrades[5]=(Icon=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Rocket',RoF=0.0,Buyer=none,UIName="HomingRocket")
    Upgrades[6]=(Icon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Medic',RoF=0.0,Buyer=none,UIName="AutoRepair")
    Upgrades[7]=(Icon=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletBurst',RoF=0.0,Buyer=none,UIName="Ammo")
    Upgrades[8]=(Icon=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto',RoF=0.0,Buyer=none,UIName="AmmoBig")
    Upgrades[9]=(Icon=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Nail',RoF=0.0,Buyer=none,UIName="Missile")
    Upgrades[10]=(Icon=Texture2D'ui_firemodes_tex.UI_FireModeSelect_NailsBurst',RoF=0.0,Buyer=none,UIName="MissileBig")
    UpgradeNames[0]="Iron Sight 1|This upgrade gives this turret level 1 firing precision.\\n+30 % accurancy."
    UpgradeNames[1]="Iron Sight 2|This upgrade gives this turret level 2 firing precision.\\n+60 % accurancy."
    UpgradeNames[2]="Eagle Eye 1|This upgrade gives this turret level 1 sight distance bonus.\\n+50 % sight distance."
    UpgradeNames[3]="Eagle Eye 2|This upgrade gives this turret level 2 sight distance bonus.\\n+100 % sight distance."
    UpgradeNames[4]="Head Hunter|This upgrade makes the turret aim at zed heads instead of body."
    UpgradeNames[5]="Homing Missiles|This upgrade makes the level 3 turret fire homing missiles instead of regular missiles.\\n-Requires level 3 turret to purchase!"
    UpgradeNames[6]="Auto Repair|This upgrade makes the turret auto regain health slowly over time when haven't taken damage for 30 seconds."
    UpgradeNames[7]="SMG Ammo|Buy 100 SMG ammo.\\n(No refund for excessive ammo)"
    UpgradeNames[8]="5x SMG Ammo|Buy 500 SMG ammo.\\n(No refund for excessive ammo)"
    UpgradeNames[9]="Missile Ammo|Buy 10 missiles.\\n(No refund for excessive ammo)"
    UpgradeNames[10]="5x Missile Ammo|Buy 50 missiles.\\n(No refund for excessive ammo)"
    begin object name=ThirdPersonHead0 class=SkeletalMeshComponent
        ReplacementPrimitive=none
    object end
    // Reference: SkeletalMeshComponent'Default__SentryTurret.ThirdPersonHead0'
    ThirdPersonHeadMeshComponent=ThirdPersonHead0
    AfflictionHandler=KFAfflictionManager'Default__SentryTurret.Afflictions'
    begin object name=FirstPersonArms class=KFSkeletalMeshComponent
        ReplacementPrimitive=none
    object end
    // Reference: KFSkeletalMeshComponent'Default__SentryTurret.FirstPersonArms'
    ArmsMesh=FirstPersonArms
    SpecialMoveHandler=KFSpecialMoveHandler'Default__SentryTurret.SpecialMoveHandler'
    AmbientAkComponent=AkComponent'Default__SentryTurret.AmbientAkSoundComponent_1'
    WeaponAkComponent=AkComponent'Default__SentryTurret.AmbientAkSoundComponent'
    WeaponAmbientEchoHandler=KFWeaponAmbientEchoHandler'Default__SentryTurret.WeaponAmbientEchoHandler'
    FootstepAkComponent=AkComponent'Default__SentryTurret.FootstepAkSoundComponent'
    DialogAkComponent=AkComponent'Default__SentryTurret.DialogAkSoundComponent'
    SightRadius=2200.0
    Mass=5500.0
    BaseEyeHeight=70.0
    EyeHeight=70.0
    Health=350
    HealthMax=350
    ControllerClass=class'SentryTurretAI'
    begin object name=SkelMesh class=SkeletalMeshComponent
        bUpdateSkelWhenNotRendered=false
        ReplacementPrimitive=none
        RBChannel=ERBCollisionChannel.RBCC_GameplayPhysics
        CollideActors=true
        BlockZeroExtent=true
        LightingChannels=(bInitialized=true,Indoor=true,Outdoor=true)
        RBCollideWithChannels=(Default=true,GameplayPhysics=true,EffectPhysics=true,BlockingVolume=true)
        Translation=(X=0.0,Y=0.0,Z=-50.0)
        Scale=2.50
    object end
    // Reference: SkeletalMeshComponent'Default__SentryTurret.SkelMesh'
    Mesh=SkelMesh
    begin object name=CollisionCylinder class=CylinderComponent
        CollisionHeight=50.0
        CollisionRadius=30.0
        ReplacementPrimitive=none
    object end
    // Reference: CylinderComponent'Default__SentryTurret.CollisionCylinder'
    CylinderComponent=CollisionCylinder
    begin object name=CollisionCylinder class=CylinderComponent
        CollisionHeight=50.0
        CollisionRadius=30.0
        ReplacementPrimitive=none
    object end
    // Reference: CylinderComponent'Default__SentryTurret.CollisionCylinder'
    Components(0)=CollisionCylinder
    begin object name=Arrow class=ArrowComponent
        ReplacementPrimitive=none
    object end
    // Reference: ArrowComponent'Default__SentryTurret.Arrow'
    Components(1)=Arrow
    begin object name=KFPawnSkeletalMeshComponent class=KFSkeletalMeshComponent
        ReplacementPrimitive=none
    object end
    // Reference: KFSkeletalMeshComponent'Default__SentryTurret.KFPawnSkeletalMeshComponent'
    Components(2)=KFPawnSkeletalMeshComponent
    Components(3)=AkComponent'Default__SentryTurret.AmbientAkSoundComponent'
    Components(4)=AkComponent'Default__SentryTurret.AmbientAkSoundComponent_1'
    Components(5)=AkComponent'Default__SentryTurret.FootstepAkSoundComponent'
    Components(6)=AkComponent'Default__SentryTurret.DialogAkSoundComponent'
    begin object name=SkelMesh class=SkeletalMeshComponent
        bUpdateSkelWhenNotRendered=false
        ReplacementPrimitive=none
        RBChannel=ERBCollisionChannel.RBCC_GameplayPhysics
        CollideActors=true
        BlockZeroExtent=true
        LightingChannels=(bInitialized=true,Indoor=true,Outdoor=true)
        RBCollideWithChannels=(Default=true,GameplayPhysics=true,EffectPhysics=true,BlockingVolume=true)
        Translation=(X=0.0,Y=0.0,Z=-50.0)
        Scale=2.50
    object end
    // Reference: SkeletalMeshComponent'Default__SentryTurret.SkelMesh'
    Components(7)=SkelMesh
    Physics=EPhysics.PHYS_Falling
    begin object name=CollisionCylinder class=CylinderComponent
        CollisionHeight=50.0
        CollisionRadius=30.0
        ReplacementPrimitive=none
    object end
    // Reference: CylinderComponent'Default__SentryTurret.CollisionCylinder'
    CollisionComponent=CollisionCylinder
}