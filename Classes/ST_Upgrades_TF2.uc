// Upgrades class for the TF2 Turret
Class ST_Upgrades_TF2 extends ST_Upgrades_Base;

var bool bRegen, bFireDamage, bFireArmor;
var float SonicDamageMultiplier;

//Handles passive upgrade effects
//NB: Only called when TurretLevel or PurchasedUpgrades is changed
simulated function UpdateUpgrades()
{
	local int i;

	// MUST BE FIRST, resets stats to level defaults so we can build them up using the purchased upgrades
	super.UpdateUpgrades();

	// Reset booleans in case an upgrade has been sold
	bRegen = false;
	bFireDamage = false;

	// Skipping the turret level-up upgrade iterate through all potential upgrades
	for(i = 1; i < TotalUpgrades; i++) // TotalUpgrades is always the last upgrade enum value, can be used as int
	{
		// Check if the upgrade has been purchased
		if(HasUpgrade(i))
		{
			// If purchased execute the associated calculation
			switch(i)
			{
				case EUpRangeA:
					TurretOwner.SetSightRadius(TurretOwner.SightRadius * UpgradeInfos[i].FValue);
					break;
				case EUpRangeB:
					TurretOwner.SetSightRadius(TurretOwner.SightRadius * UpgradeInfos[i].FValue);
					break;
				case EUpAccuracyA:
					TurretOwner.AccuracyMod[EPrimaryFire] *= UpgradeInfos[i].FValue;
					break;
				case EUpAccuracyB:
					TurretOwner.AccuracyMod[EPrimaryFire] *= UpgradeInfos[i].FValue;
					break;
				case EUpHeadshots:
					break;
				case EUpHomingMissiles:
					break;
				case EUpAutoRepair:
					bRegen = true;
					break;
				case EUpPrimaryDamageType:
					bFireDamage = true;
					break;
				case EUpDamageReduceA:
					break;
				case EUpDamageReduceB:
					bFireArmor = true;
					break;
				case EUpTurnRadiusA:
					if(HasUpgrade(EUpTurnRadiusB)) // Dont decrease the turn radius if a better one is purchased
						break;
				case EUpTurnRadiusB:
					if(HasUpgrade(EUpTurnRadiusC)) // Dont decrease the turn radius if a better one is purchased
						break;
				case EUpTurnRadiusC:
					TurretOwner.SetTurnRadius(UpgradeInfos[i].FValue); // Executed for all three turn radius upgrades
					break;
			}
		}
	}
}

//Handles periodic upgrade effects
simulated function UpgradesTimer()
{
	// Checks regen status boolean and if the turret is hurt applys effect
	// TODO: use clock to test if running the Min() calculation every time is faster/equivalent to checking the current health every time
	if(bRegen && ST_Turret_Base(Owner).Health < ST_Turret_Base(Owner).HealthMax)
	{
		//Applys Effect (Min returns an integer)
		ST_Turret_Base(Owner).Health = Min(ST_Turret_Base(Owner).Health + UpgradeInfos[EUpAutoRepair].Value, ST_Turret_Base(Owner).HealthMax);
	}
}

//Handles upgrades that modify damage taken
//NB: Should be reasonably slim to decrease overhead
simulated function ModifyDamageTaken(out int InDamage, optional class<DamageType> InDamageType, optional Controller InstigatedBy)
{
	// Flat Sonic damage reduction
	if(InDamageType.IsA('KFDT_Sonic')) // Try to cast to Sonic damage
		InDamage *= SonicDamageMultiplier;

	// Check for Fire damage reduction upgrade
	if(bFireArmor)
	{
		TurretOwner.Controller.GotoState();
		if(InDamageType.IsA('KFDT_Fire')) // Try to cast to Fire damage
		{
			InDamage *= UpgradeInfos[EUpDamageReduceA].FValue;
		}
	}
}

//Handles upgrades that modify damage given
//NB: Should be as slim as possible to decrease overhead
simulated function ModifyDamageGiven(out int InDamage, optional Actor HitActor, optional out class<KFDamageType> OutDamageType, optional int HitZoneIdx)
{
	// Check for Fire damage upgrade
	if(bFireDamage)
	{
		//Every 10th bullet the damage type gets set to fire damage
		if(ST_Turret_Base(Owner).FireCounter[0] % 10 == 0) // TODO: Find faster math, maybe bitshift
			OutDamageType = class'KFDT_Fire';
	}

}

defaultproperties
{
	bRegen = false
	SonicDamageMultiplier = 0.1f // Reduces all sonic damage by 90%

	// LEVELS
	LevelInfos(0) = {(
		IconIndex = `ICON_LEVEL_1,
		TurretArch = KFCharacterInfo_Monster'Turret_TF2.Arch.Turret1Arch',

		Title="Level 1",
		Description="Low level TF2 sentry turret",

		Cost=1000,
		BaseDamage[0]=10,
		BaseMaxHealth=350,
		BaseRoF=0.3f,
		BaseMaxAmmoCount[0]=1000,
		BaseTurnRadius=0.6f,
		BaseSightRadius=1800.0f,
		BaseAccuracyMod=0.05f
	)}

	LevelInfos(1)={(
		IconIndex=`ICON_LEVEL_2,
		TurretArch=KFCharacterInfo_Monster'Turret_TF2.Arch.Turret2Arch',

		Title="Level 2",
		Description="Mid level TF2 sentry turret",

		Cost=1500,
		BaseDamage[0]=11,
		BaseMaxHealth=400,
		BaseRoF=0.125f,
		BaseMaxAmmoCount[0]=1500,
		BaseTurnRadius=0.6f,
		BaseSightRadius=1800.0f,
		BaseAccuracyMod=0.05f
	)}

	LevelInfos(2)={(
		IconIndex=`ICON_LEVEL_3,
		TurretArch=KFCharacterInfo_Monster'Turret_TF2.Arch.Turret3Arch',

		Title="Level 3",
		Description="High level TF2 sentry turret",

		Cost=2500,
		BaseDamage[0]=13,
		BaseDamage[1]=1000,
		BaseMaxHealth=600,
		BaseRoF=0.1f,
		BaseMaxAmmoCount[0]=2000,
		BaseMaxAmmoCount[1]=50,
		BaseTurnRadius=0.6f,
		BaseSightRadius=1800.0f,
		BaseAccuracyMod=0.05f
	)}

	// AMMO
	AmmoInfos(EPrimaryFire) = {(
		IconIndex = `ICON_AMMO_BULLETS,
		CostPerRound = 1,
		BuyAmount = 250
	)}

	AmmoInfos(ESecondaryFire) = {(
		IconIndex = `ICON_AMMO_ROCKET,
		CostPerRound = 20,
		BuyAmount = 20
	)}

	// UPGRADES
	UpgradeInfos(EUpRangeA)=(bIsEnabled=True)
	UpgradeInfos(EUpRangeB)=(bIsEnabled=True)
	UpgradeInfos(EUpAccuracyA)=(bIsEnabled=True)
	UpgradeInfos(EUpAccuracyB)=(bIsEnabled=True)
	UpgradeInfos(EUpHeadshots)=(bIsEnabled=True)
	UpgradeInfos(EUpHomingMissiles)=(bIsEnabled=True)
	UpgradeInfos(EUpAutoRepair)=(bIsEnabled=True)
	UpgradeInfos(EUpDamageReduceB)=(bIsEnabled=True)
	UpgradeInfos(EUpPrimaryDamageType)=(bIsEnabled=True)
	UpgradeInfos(EUpTurnRadiusA)=(bIsEnabled=True)
	UpgradeInfos(EUpTurnRadiusB)=(bIsEnabled=True)

	UpgradeInfos(EUpTurnRadiusC)={(
		Cost=1000,
		Title="Turning Radius",
		Description="Allows the turret to turn in a wider circle to target Zeds",
		bIsEnabled=True,
		IconIndex=`ICON_DEFAULT
	)}
}