//Handles replicating current server info to the client

Class SentryMainRep extends ReplicationInfo
	transient
	config(SentryTurret);

var repnotify ObjectReferencer ObjRef;
var ObjectReferencer BaseRef;

var repnotify config byte MaxTurretsPerUser, MapMaxTurrets, HealthRegenRate;
var repnotify config int PreviewRotationRate, MissileSpeed, HealPerHit, MissileHitDamage, HealthLostNoOwner, RandomDamagePercent;
var repnotify config float BaseTurnRadius, TurretPreviewDelay, StartingAmmoMultiplier, WeaponTextScale, RefundMultiplier, MinPlacementDistance, BaseAccuracyMod, BaseSightRadius, SonicDamageMultiplier;
var repnotify config int MaxAmmoCount[2];
var repnotify config bool bCanDropWeapon, bRandomDamage, bHeavyAttackToSell;

const MAX_TURRET_LEVELS = 3;
const ETU_MAXUPGRADES = 11;
const ETU_IronSightA = 0;
const ETU_IronSightB = 1;
const ETU_EagleEyeA = 2;
const ETU_EagleEyeB = 3;
const ETU_Headshots = 4;
const ETU_HomingMissiles = 5;
const ETU_AutoRepair = 6;
const ETU_AmmoSMG = 7;
const ETU_AmmoSMGBig = 8;
const ETU_AmmoMissiles = 9;
const ETU_AmmoMissilesBig = 10;

struct FTurretLevelCfg
{
	var repnotify config int Cost, Damage, Health;
	var repnotify config float RoF;
};
var repnotify config FTurretLevelCfg LevelCfgs[MAX_TURRET_LEVELS];

var repnotify config int UpgradeCosts[ETU_MAXUPGRADES];
var config int ConfigVersion;

replication
{
	if (true)
		BaseTurnRadius,
		PreviewRotationRate,
		bCanDropWeapon,
		TurretPreviewDelay,
		StartingAmmoMultiplier,
		MissileSpeed,
		WeaponTextScale,
		MaxTurretsPerUser,
		MapMaxTurrets,
		MinPlacementDistance,
		HealPerHit,
		MissileHitDamage,
		HealthRegenRate,
		LevelCfgs,
		UpgradeCosts,
		MaxAmmoCount,
		HealthLostNoOwner,
		RefundMultiplier,
		RandomDamagePercent,
		SonicDamageMultiplier,
		bRandomDamage,
		BaseAccuracyMod,
		bHeavyAttackToSell,
		BaseSightRadius,
		ObjRef;
}

// Ensures there is always one spawned instance of this class on the server.
simulated static final function SentryMainRep FindContentRep(WorldInfo Level)
{
	local SentryMainRep H;
	
	//Search through spawned actors for an existing instance of this class
	foreach Level.DynamicActors(class'SentryMainRep', H)
		if(H != None)
			return H;
	// If server and none exists spawn a new instance
	if(Level.NetMode != NM_Client)
	{
		H = Level.Spawn(class'SentryMainRep');
		return H;
	}
	return None;
}

function PostBeginPlay()
{
	local KFGameInfo K;

	UpdateConfig();

	// Replace scriptwarning spewing DialogManager.
	K = KFGameInfo(WorldInfo.Game);
	if(K != None)
	{
		if(K.DialogManager != None)
		{
			if(K.DialogManager.Class == Class'KFDialogManager')
			{
				K.DialogManager.Destroy();
				K.DialogManager = Spawn(class'KFDialogManagerSentry');
			}
		}
		else if(K.DialogManagerClass == Class'KFDialogManager')
			K.DialogManagerClass=class'KFDialogManagerSentry';
	}

	//BaseRef is defined in default properties as ObjectReferencer'tf2sentry.Arch.TurretObjList'
	//Currently being depricated
	ObjRef = BaseRef;
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'ObjRef' && ObjRef != None && WorldInfo.NetMode == NM_Client)
		UpdateInstances();
}

simulated final function UpdateInstances()
{
	local SentryTurret T;
	local KFWeap_EngWrench W;

	foreach DynamicActors(class'KFWeap_EngWrench', W)
		W.InitConfigDependant();
	foreach WorldInfo.AllPawns(class'SentryTurret', T)
	{
		T.UpdateConfigValues();
	}
}

simulated final function UpdateConfig()
{
	//local bool ErrorFound;
	//ErrorFound = false;

	if(Default.ConfigVersion != 2) // Increment version to reset/update old configs
	{
		Default.MaxTurretsPerUser = 3;
		Default.MapMaxTurrets = 12;
		Default.MinPlacementDistance = 250;
		Default.HealPerHit = 35;
		Default.MissileHitDamage = 1000;
		Default.HealthRegenRate = 10;
		Default.LevelCfgs[0].Cost = 2000;
		Default.LevelCfgs[0].Damage = 10;
		Default.LevelCfgs[0].Health = 350;
		Default.LevelCfgs[0].Rof = 0.3f;
		Default.LevelCfgs[1].Cost = 1500;
		Default.LevelCfgs[1].Damage = 11;
		Default.LevelCfgs[1].Health = 400;
		Default.LevelCfgs[1].RoF = 0.125f;
		Default.LevelCfgs[2].Cost = 2500;
		Default.LevelCfgs[2].Damage = 13;
		Default.LevelCfgs[2].Health = 600;
		Default.LevelCfgs[2].RoF = 0.1f;
		Default.UpgradeCosts[ETU_IronSightA] = 100;
		Default.UpgradeCosts[ETU_IronSightB] = 200;
		Default.UpgradeCosts[ETU_EagleEyeA] = 250;
		Default.UpgradeCosts[ETU_EagleEyeB] = 450;
		Default.UpgradeCosts[ETU_Headshots] = 500;
		Default.UpgradeCosts[ETU_HomingMissiles] = 400;
		Default.UpgradeCosts[ETU_AutoRepair] = 650;
		Default.UpgradeCosts[ETU_AmmoSMG] = 45;
		Default.UpgradeCosts[ETU_AmmoSMGBig] = 200;
		Default.UpgradeCosts[ETU_AmmoMissiles] = 100;
		Default.UpgradeCosts[ETU_AmmoMissilesBig] = 450;
		Default.MaxAmmoCount[0] = 2000;
		Default.MaxAmmoCount[1] = 50;
		Default.HealthLostNoOwner = 70; // >= 0
		Default.RefundMultiplier = 0.7f; // 0 to 1
		Default.RandomDamagePercent = 10; // +/- percent of damage, 0 to 100
		Default.SonicDamageMultiplier = 0.1f; // 0 to 1
		Default.bRandomDamage = true;
		Default.BaseAccuracyMod = 0.06f;
		Default.bHeavyAttackToSell = true;
		Default.BaseSightRadius = 2200.0;
		Default.WeaponTextScale = 1.2f;
		Default.MissileSpeed = 3000;
		Default.StartingAmmoMultiplier = 0.1f;
		Default.TurretPreviewDelay = 0.3f;
		Default.bCanDropWeapon = true;
		Default.PreviewRotationRate = 10.0f;
		Default.BaseTurnRadius = 0.6f;
		Default.ConfigVersion = 2;
		StaticSaveConfig();
	}

	/*
	if(HealthLostNoOwner < 0) {
		Default.HealthLostNoOwner = 0;
		ErrorFound = true;
	}
	if(RefundMultiplier != clamp(RefundMultiplier, 0, 1)) {
		Default.RefundMultiplier = clamp(RefundMultiplier, 0, 1);
		ErrorFound = true;
	}
	if(RandomDamagePercent != clamp(RandomDamagePercent, 0, 100)) {
		Default.RandomDamagePercent = clamp(RandomDamagePercent, 0, 100);
		ErrorFound = true;
	}
	if(SonicDamageMultiplier != clamp(SonicDamageMultiplier, 0, 1)) {
		Default.SonicDamageMultiplier = clamp(SonicDamageMultiplier, 0, 1);
		ErrorFound = true;
	}

	if(ErrorFound) StaticSaveConfig();
	*/
}

//TODO Expose net update frequency to config
defaultproperties
{
   BaseRef = ObjectReferencer'tf2sentry.Arch.TurretObjList'
   NetUpdateFrequency = 4.000000
}
