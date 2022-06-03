Class ST_Upgrades_Example extends ST_Upgrades_Base;

//Runs whenever the upgrades or level changes
simulated function UpdateUpgrades()
{
	local int i;

	// MUST BE FIRST, resets stats to level defaults so we can build them up using the purchased upgrades
	super.UpdateUpgrades();

	// Reset booleans in case an upgrade has been sold
	//bRegen = false;

	// Skipping the turret level-up upgrade iterate through all potential upgrades
	for(i = 1; i < TotalUpgrades; i++) // TotalUpgrades is always the last upgrade enum value, can be used as int
	{
		// Check if the upgrade has been purchased
		if(HasUpgrade(i))
		{
			// If purchased execute the associated calculation
			switch(i)
			{
				case EUpEnum:
					break;
				case EUpEnum:
					break;
				case EUpEnum:
					break;
				case EUpEnum:
					break;
			}
		}
	}
}

//Update on a fixed tick
simulated function UpgradesTimer()
{
	// It is best practice to store a value/second in BValue and then multiply it by TimerPeriod to get Value or FValue when used here, this allows TimerPeriod to change without invalidating the upgrade
}

simulated function ModifyDamageTaken(out int InDamage, optional class<DamageType> InDamageType, optional Controller InstigatedBy)
{
}

simulated function ModifyDamageGiven(out int InDamage, optional Actor HitActor, optional out class<DamageType> OutDamageType, optional int HitZoneIdx)
{
}

defaultproperties
{
	// LEVELS
	LevelInfos(0) = {(									// Must have at least this entry for level 1, you can have up to 254 levels
		IconIndex = `ICON_LEVEL_1,
		TurretArch = KFCharacterInfo_Monster'Turret_TF2.Arch.Turret1Arch',	// The mesh/texture data is held in this archetype

		Title="Level 1",								// Used for the upgrades menu (shown when buying this levelup)
		Description="Low level TF2 sentry turret",		// Used for the upgrades menu (shown when buying this levelup)

		Cost=1000,
		BaseDamage[0]=10,
		BaseMaxHealth=350,
		BaseRoF=0.3f,
		BaseMaxAmmoCount[0]=1000,
		BaseTurnRadius=0.6f,
		BaseSightRadius=1800.0f,
		BaseAccuracyMod=0.05f
	)}

	// AMMO
	AmmoInfos(EPrimaryFire)={(
		IconIndex=`ICON_AMMO_BULLETS,					// The ` mark means this is a global constant from the Globals.uci file, they're set up like enums though
		CostPerRound=2
	)}

	//UPGRADES
	UpgradeInfos(EUpHeadshots)=(bIsEnabled=True)		// The minimum entry required to turn an upgrade on

	UpgradeInfos(EUpRangeA)={(
		//Cost = 200,									// If the default value from ST_Upgrades_Base is fine you don't need to list it here
		Title = "Crazy range up",
		Description = "Increase range by 25%",
		BValue = 1.25f,									// Only work with BValue here, not Value, FValue, or ValueModifier
		bIsEnabled = True,								// bIsEnabled must be set to true to show in menu
		RequiredUpgrades = (EUpAccuracyA, EUpRangeA)	// Must have already purchased these upgrades for this one to show in menu
		ExcludedUpgrades = (EUpRangeB)					// Must NOT have already purchased these upgrades for this one to show in menu
	)}
}