class PCF_Skill_Gambler extends WMUpgrade_Skill;

var float Probability;
var array<float> CritDamage;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{	
	local PCF_Skill_Gambler_Helper UPG;

	if (MyKFW != None && MyKFW.Owner != None && FRand() <= default.Probability)
	{
		InDamage += Round(float(DefaultDamage) * default.CritDamage[upgLevel - 1]);

		UPG = GetHelper(KFPawn(MyKFW.Owner));
		if (UPG != None)
			UPG.ActiveEffect();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local PCF_Skill_Gambler_Helper UPG;
	local bool bFound;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
	{
		bFound = False;
		foreach OwnerPawn.ChildActors(class'PCF_Skill_Gambler_Helper', UPG)
		{
			bFound = True;
			break;
		}

		if (!bFound)
			UPG = OwnerPawn.Spawn(class'PCF_Skill_Gambler_Helper', OwnerPawn);
	}
}

static function PCF_Skill_Gambler_Helper GetHelper(KFPawn OwnerPawn)
{
	local PCF_Skill_Gambler_Helper UPG;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'PCF_Skill_Gambler_Helper', UPG)
		{
			return UPG;
		}

		//Should have one
		UPG = OwnerPawn.Spawn(class'PCF_Skill_Gambler_Helper', OwnerPawn);
	}

	return UPG;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local PCF_Skill_Gambler_Helper UPG;

	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'PCF_Skill_Gambler_Helper', UPG)
		{
			UPG.Destroy();
		}
	}
}

defaultproperties
{
	Probability=0.03f
	CritDamage(0)=5.0f
	CritDamage(1)=12.0f

	upgradeName="Gambler"
	upgradeDescription(0)="3% chance with <font color=\"#eaeff7\">all weapons</font> to crit for 500% damage"
	upgradeDescription(1)="3% chance with <font color=\"#eaeff7\">all weapons</font> to crit for <font color=\"#b346ea\">1200%</font> damage"
	upgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Ruthless'
	upgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Ruthless_Deluxe'

	Name="Default__PCF_Skill_Gambler"
}
