Class ST_Upgrades_Example extends ST_Upgrades_Base;

simulated function UpdateUpgrades()
{
}

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
}