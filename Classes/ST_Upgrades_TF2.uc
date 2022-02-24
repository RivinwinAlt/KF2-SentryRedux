// Upgrades class for the TF2 Turret
Class ST_Upgrades_TF2 extends ST_Upgrades_Base;

/*
simulated final function SetUpgrades()
{
	if(HasUpgradeFlags(ETU_IronSightB))
		AccuracyMod = BaseAccuracyMod / 4.0f;
	else if(HasUpgradeFlags(ETU_IronSightA))
		AccuracyMod = BaseAccuracyMod / 2.0f;
	else AccuracyMod = BaseAccuracyMod;
	
	if(WorldInfo.NetMode != NM_Client)
	{
		SightRadius = BaseSightRadius;
		if(HasUpgradeFlags(ETU_EagleEyeB))
			SightRadius = BaseSightRadius * 1.3f;
		else if(HasUpgradeFlags(ETU_EagleEyeA))
			SightRadius = BaseSightRadius * 1.6f;
		
		bHeadHunter = HasUpgradeFlags(ETU_Headshots);
		bHasAutoRepair = HasUpgradeFlags(ETU_AutoRepair);
		
		if(bHasAutoRepair && AutoRepairState == 0 && Health < HealthMax)
		{
			AutoRepairState = 1;
			SetTimer(30, false, 'AutoRepairTimer');
		}
	}
}
*/

//Handles passive upgrade effects
//NB: Only called when TurretLevel or PurchasedUpgrades is changed
simulated function UpdateUpgrades()
{
	local int i;

	for(i = 1; i < TotalUpgrades; i++) // TotalUpgrades is always the last upgrade enum value, can be used as int
	{
		if(HasUpgrade(i))
		{
			switch(i)
			{
				case EUpRangeA:
					break;
				case EUpRangeB:
					break;
				case EUpAccuracyA:
					break;
				case EUpAccuracyB:
					break;
				case EUpHeadshots:
					break;
				case EUpHomingMissiles:
					break;
				case EUpAutoRepair:
					//Updates value using config modifier to be within expected limits (Clamp returns an integer)
					UpgradeInfos[i].Value = Clamp(UpgradeInfos[i].Value * UpgradeInfos[i].ValueModifier, 1, St_Base(Owner).HealthMax);
					break;
				case EUpFireDamage:
					break;
				case EUpDamageReduceA:
					//Updates value using config modifier to be within expected limits (FClamp returns a float)
					UpgradeInfos[i].FValue = FClamp(UpgradeInfos[i].Value * UpgradeInfos[i].ValueModifier, 1, St_Base(Owner).HealthMax);
					break;
				case EUpDamageReduceB:
					break;
			}
		}
	}
}

//Handles periodic upgrade effects
simulated function Timer()
{
	//Checks for the AutoRepair Upgrade
	if(HasUpgrade(EUpAutoRepair) && St_Base(Owner).Health < St_Base(Owner).HealthMax)
	{
		//Applys Effect (Min returns an integer)
		St_Base(Owner).Health = Min(St_Base(Owner).Health + UpgradeInfos[EUpAutoRepair].Value, St_Base(Owner).HealthMax);
	}
}

//Handles upgrades that modify damage taken
//NB: Should be reasonably slim to decrease overhead
simulated function ModifyDamageTaken(out int InDamage, optional class<DamageType> DamageType, optional Controller InstigatedBy)
{
	if(HasUpgrade(EUpDamageReduceA))
	{
		//If the damage type being taken is derived from KFDT_Fire decrease the damage amount
		if(ClassIsChildOf(DamageType, class'KFDT_Fire'))
		{

		}
	}
}

//Handles upgrades that modify damage given
//NB: Should be as slim as possible to decrease overhead
simulated function ModifyDamageGiven(out int InDamage, optional KFPawn_Monster MyKFPM, optional out class<KFDamageType> DamageType, optional int HitZoneIdx)
{
	if(HasUpgrade(EUpFireDamage))
	{
		//Every 10th bullet the damage type gets set to fire damage
		if(St_Base(Owner).FireCounter[0] % 10 == 0)
			DamageType = class'KFDT_Fire';
	}
}

defaultproperties
{
	LevelInfos(0)={(
		Icon=Texture2D'Turret_TF2.HUD.Level1',		//TODO: Change to reference by path to decrease memory used by LevelInfos
		TurretArch=KFCharacterInfo_Monster'tf2sentry.Arch.Turret1Arch',
		FiringSounds[0]=SoundCue'tf2sentry.Sounds.sentry_shoot_Cue',

		Title="Level 1",
		Description="Low level TF2 sentry turret",

		Cost=1000,
		BaseDamage=10,
		BaseMaxHealth=350,
		BaseRoF=0.3f,
		BaseMaxAmmoCount[0]=1000
	)}

	LevelInfos(1)={(
		Icon=Texture2D'Turret_TF2.HUD.Level2',		//TODO: Change to reference by path to decrease memory used by LevelInfos
		TurretArch=KFCharacterInfo_Monster'tf2sentry.Arch.Turret2Arch',
		FiringSounds[0]=SoundCue'tf2sentry.Sounds.sentry_shoot2_Cue',

		Title="Level 2",
		Description="Mid level TF2 sentry turret",

		Cost=1500,
		BaseDamage=11,
		BaseMaxHealth=400,
		BaseRoF=0.125f,
		BaseMaxAmmoCount[0]=1500
	)}

	LevelInfos(2)={(
		Icon=Texture2D'Turret_TF2.HUD.Level3',		//TODO: Change to reference by path to decrease memory used by LevelInfos
		TurretArch=KFCharacterInfo_Monster'tf2sentry.Arch.Turret3Arch',
		FiringSounds[0]=SoundCue'tf2sentry.Sounds.sentry_shoot3_Cue',

		Title="Level 3",
		Description="High level TF2 sentry turret",

		Cost=2500,
		BaseDamage=13,
		BaseMaxHealth=600,
		BaseRoF=0.1f,
		BaseMaxAmmoCount[0]=2000,
		BaseMaxAmmoCount[1]=50
	)}

	UpgradeInfos(EUpRangeA)=(bIsEnabled=True)

	UpgradeInfos(EUpRangeB)=(bIsEnabled=True)

	UpgradeInfos(EUpAccuracyA)=(bIsEnabled=True)
	
	UpgradeInfos(EUpAccuracyB)=(bIsEnabled=True)
	
	UpgradeInfos(EUpHeadshots)=(bIsEnabled=True)
	
	UpgradeInfos(EUpHomingMissiles)=(bIsEnabled=True)
	
	UpgradeInfos(EUpAutoRepair)=(bIsEnabled=True)
	
	UpgradeInfos(EUpFireDamage)=(bIsEnabled=False)

	UpgradeInfos(EUpDamageReduceA)=(bIsEnabled=False)

	UpgradeInfos(EUpDamageReduceB)=(bIsEnabled=False)
}