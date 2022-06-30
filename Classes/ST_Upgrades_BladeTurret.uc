// Upgrades class for the TF2 Turret
Class ST_Upgrades_BladeTurret extends ST_Upgrades_Base;

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
	bFireArmor = false;

	// Skipping the turret level-up upgrade iterate through all potential upgrades
	for(i = 1; i < TotalUpgrades; i++) // TotalUpgrades is always the last upgrade enum value, can be used as int
	{
		// Check if the upgrade has been purchased
		if(HasUpgrade(i))
		{
			// If purchased execute the associated calculation
			switch(i)
			{
				case EUpPrimaryDamage:
					TurretOwner.Damage[EPrimaryFire] *= UpgradeInfos[i].FValue;
					UpgradeInfos[EUpPrimaryDamage].Cost = UpgradeInfos[EUpPrimaryDamage].InitialCost * UpgradeInfos[EUpPrimaryDamage].CurrentLevel;
					break;
				case EUpSecondaryDamage:
					TurretOwner.Damage[ESecondaryFire] *= UpgradeInfos[i].FValue;
					UpgradeInfos[EUpSecondaryDamage].Cost = UpgradeInfos[EUpSecondaryDamage].InitialCost * UpgradeInfos[EUpSecondaryDamage].CurrentLevel;
					break;
				case EUpHealthUp:
					TurretOwner.HealthMax *= UpgradeInfos[i].FValue;
					UpgradeInfos[EUpHealthUp].Cost = UpgradeInfos[EUpHealthUp].InitialCost * UpgradeInfos[EUpHealthUp].CurrentLevel;
					break;
				case EUpFireRate:
					TurretOwner.RoF[EPrimaryFire] *= UpgradeInfos[i].FValue;
					UpgradeInfos[EUpFireRate].Cost = UpgradeInfos[EUpFireRate].InitialCost * UpgradeInfos[EUpFireRate].CurrentLevel;
					break;
				case EUpRange:
					TurretOwner.SetSightRadius(TurretOwner.SightRadius * UpgradeInfos[i].FValue);
					UpgradeInfos[EUpRange].Cost = UpgradeInfos[EUpRange].InitialCost * UpgradeInfos[EUpRange].CurrentLevel;
					break;
				case EUpAccuracy:
					TurretOwner.AccuracyMod[EPrimaryFire] *= UpgradeInfos[i].FValue;
					UpgradeInfos[EUpAccuracy].Cost = UpgradeInfos[EUpAccuracy].InitialCost * UpgradeInfos[EUpAccuracy].CurrentLevel;
					break;
				case EUpTurnRadiusA:
					if(HasUpgrade(EUpTurnRadiusB)) // Dont decrease the turn radius if a better one is purchased
					break;
				case EUpTurnRadiusB:
					if(HasUpgrade(EUpTurnRadiusC)) // Dont decrease the turn radius if a better one is purchased
					break;
				case EUpTurnRadiusC:
					TurretOwner.SetTurnRadius(UpgradeInfos[i].FValue); // Executed for all three turn radius upgrades
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
				case EUpPrimaryAmmoUp:
					TurretOwner.MaxAmmoCount[0] *= UpgradeInfos[i].FValue;
					break;
				case EUpSecondaryAmmoUp:
					TurretOwner.MaxAmmoCount[1] *= UpgradeInfos[i].FValue;
					break;
				case EUpHeadshots:
					break;
				case EUpWeaponBehaviour:
					break;
				case EUpAutoRepair:
					bRegen = true;
					break;
			}
		}
	}
}

//Handles periodic upgrade effects
simulated function UpgradesTimer()
{
	// Checks regen status boolean and if the turret is hurt applys effect
	// TODO: use benchmarker to test if running the Min() calculation every time is faster/equivalent to checking the current health every time
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
	ShieldAbsorb(InDamage); // If you remove this line Armor will not be taken into account for the turret

	// Check for Fire damage reduction upgrade
	if(bFireArmor)
	{
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
}

defaultproperties
{
	bRegen=false

	//Turret Level Settings
	LevelInfos(0)={(
		IconIndex=`ICON_LEVEL_1,
		TurretArch=KFCharacterInfo_Monster'Turret_TF2.Arch.Turret1Arch',

		Title="Level 1",
		Description="Low level TF2 sentry turret",

		Cost = 1000,
		BaseMaxHealth = 350,
		BaseRoF[EPrimaryFire] = 0.3f,
		BaseDamage[EPrimaryFire] = 10,
		BaseMaxAmmoCount[EPrimaryFire] = 1000,
		BaseTurnRadius = 0.6f,
		BaseSightRadius = 1800.0f,
		BaseAccuracyMod[EPrimaryFire] = 0.05f
	)}

	LevelInfos(1) = {(
		IconIndex = `ICON_LEVEL_2,
		TurretArch = KFCharacterInfo_Monster'Turret_TF2.Arch.Turret2Arch',

		Title = "Level 2",
		Description = "Mid level TF2 sentry turret",

		Cost = 1500,
		BaseDamage[EPrimaryFire] = 11,
		BaseMaxHealth = 400,
		BaseRoF[EPrimaryFire] = 0.125f,
		BaseMaxAmmoCount[EPrimaryFire] = 1500,
		BaseTurnRadius = 0.6f,
		BaseSightRadius = 1800.0f,
		BaseAccuracyMod[EPrimaryFire] = 0.05f
	)}

	LevelInfos(2) = {(
		IconIndex = `ICON_LEVEL_3,
		TurretArch = KFCharacterInfo_Monster'Turret_TF2.Arch.Turret3Arch',

		Title = "Level 3",
		Description = "High level TF2 sentry turret",

		Cost = 2500,
		BaseDamage[EPrimaryFire] = 13,
		BaseDamage[ESecondaryFire] = 1000,
		BaseMaxHealth = 600,
		BaseRoF[EPrimaryFire] = 0.1f,
		BaseMaxAmmoCount[EPrimaryFire] = 2000,
		BaseMaxAmmoCount[ESecondaryFire] = 50,
		BaseTurnRadius = 0.6f,
		BaseSightRadius = 1800.0f,
		BaseAccuracyMod[EPrimaryFire] = 0.05f
	)}

	// Ammo Settings
	AmmoInfos(EPrimaryFire) = (CostPerRound = 2, BuyAmount = 250)
	AmmoInfos(ESecondaryFire) = (CostPerRound = 20, BuyAmount = 20)

	// Upgrade Settings
	UpgradeInfos(EUpPrimaryDamage) = (bIsEnabled=True)
	UpgradeInfos(EUpSecondaryDamage) = (bIsEnabled=True)
	UpgradeInfos(EUpHealthUp) = (bIsEnabled=True)
	UpgradeInfos(EUpFireRate) = (bIsEnabled=True)
	UpgradeInfos(EUpRange) = (bIsEnabled=True)
	UpgradeInfos(EUpAccuracy) = (bIsEnabled=True)
	UpgradeInfos(EUpTurnRadiusA) = (bIsEnabled=True)
	UpgradeInfos(EUpTurnRadiusB) = (bIsEnabled=True)
	UpgradeInfos(EUpTurnRadiusC) = (bIsEnabled=True)
	UpgradeInfos(EUpDamageReduceB) = (bIsEnabled=True)
	UpgradeInfos(EUpPrimaryAmmoUp) = (bIsEnabled=True)
	UpgradeInfos(EUpSecondaryAmmoUp) = (bIsEnabled=True)
	UpgradeInfos(EUpHeadshots) = (bIsEnabled=True)
	UpgradeInfos(EUpWeaponBehaviour) = (bIsEnabled=True)
	UpgradeInfos(EUpAutoRepair) = (bIsEnabled=True)
}