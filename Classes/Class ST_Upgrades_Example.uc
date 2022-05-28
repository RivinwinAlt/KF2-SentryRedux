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
	
}

simulated function ModifyDamageTaken(out int InDamage, optional class<DamageType> InDamageType, optional Controller InstigatedBy)
{
}

simulated function ModifyDamageGiven(out int InDamage, optional Actor HitActor, optional out class<DamageType> OutDamageType, optional int HitZoneIdx)
{
}

defaultproperties
{
	AmmoInfos(EPrimaryFire)={(
		IconIndex=`ICON_AMMO_BULLETS,
		CostPerRound=1
	)}

	UpgradeInfos(EUpRangeA)={(
		Cost=200,
		Title="Crazy range up",
		Description="Increase range by 25%",
		BValue=1.25f,
		bIsEnabled=False,
		RequiredUpgrades=(EUpAccuracyA, EUp)
	)}
}