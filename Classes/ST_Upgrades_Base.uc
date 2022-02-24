class ST_Upgrades_Base extends Info;

struct LevelInfo
{
	var Texture2D Icon;		//TODO: Change to reference by path to decrease memory used by LevelInfos
	var Color DrawColor;

	var KFCharacterInfo_Monster TurretArch;

	var string Title, Description;
	var int Cost, BaseDamage, BaseMaxHealth, RequirementMask;
	var float BaseRoF, BaseTurnRadius, BaseAccuracyMod;

	var int BaseMaxAmmoCount[3];
	var SoundCue FiringSounds[3];

	structdefaultproperties
	{
		RequirementMask = 0;		//Going up a level can be dependant on having certain upgrades
		DrawColor = (R=220,G=220,B=0,A=255); //Default color is gold
		BaseTurnRadius = 0.6f;
		BaseAccuracyMod = 0.06f;
		BaseMaxAmmoCount[0] = 0;	//Disabled by default
		BaseMaxAmmoCount[1] = 0;	//Disabled by default
		BaseMaxAmmoCount[2] = 0;	//Disabled by default
	}
};
var array<LevelInfo> LevelInfos;	//Holds all upgrades in an iterable list

struct UpgradeInfo
{
	var Texture2D Icon;		//TODO: Change to reference by path to decrease memory used by LevelInfos
	var Color DrawColor;

	var int Cost;
	var byte RequiredLevel;			//Minimum turret level for upgrade to show in menu
	var int RequirementMask;		//Sum of mask values, required upgrades for upgrade to show in menu
	var int Value;					//Reserved for integer math to increase speed
	var float FValue;				//Reserved for floating point math to allow scaling
	var float ValueModifier;	//Exposed in config file to allow effect scaling by user
	var string Title, Description;
	var bool bIsEnabled;

	structdefaultproperties
	{
		RequiredLevel = 0;			//Level 0 turrets have not finished building / been initialized
		RequirementMask = 0;		//Defaults to 'no required mods'
		DrawColor = (R=255, G=255, B=255, A=255);	//Defaults to white icon
		ValueModifier = 1.0f;
		bIsEnabled = False;			//Will not show in menu unless enabled in extended upgrades class
	}
};
var array<UpgradeInfo> UpgradeInfos;

//max number of enums (and upgrades) is 32 not including EUpLevelUp and TotalUpgrades
//order of enums is order in menu
enum UpgradeEnums 
{
	EUpLevelUp, //Dont mask
	EUpRangeA, //mask 1
	EUpRangeB, //mask 2
	EUpAccuracyA, //mask 4
	EUpAccuracyB, //mask 8
	EUpHeadshots, //mask 16
	EUpHomingMissiles, //mask 32
	EUpAutoRepair, //mask 64
	EUpFireDamage, //mask 128
	EUpDamageReduceA, //mask 256
	EUpDamageReduceB, //mask 512

	TotalUpgrades //as an int represents the total number of upgrades available
};
var array<int> AvailableUpgrades;

var repnotify byte TurretLevel;
var repnotify int PurchasedUpgrades;
var byte InitState;

replication
{
	if (true)
		PurchasedUpgrades, TurretLevel;
}

simulated event ReplicatedEvent( name VarName )
{
	if( VarName == 'PurchasedUpgrades' )
	{
		Refresh();
	}
}

simulated function Refresh()
{
	//local SentryUI_Network TempSN;

	SetLevelUpgrade();
	UpdateUpgrades();
	CalcAvailableUpgrades();

	//foreach CurrentUsers(TempSN)
}

function bool HasUpgrade(int Index)
{
	return ((1 << Index - 1) & PurchasedUpgrades) > 0; // subtract 1 because EUpLevelUp doesnt store to PurchasedVariables
}

function BoughtUpgrade(int Index)
{
	if(Index == EUpLevelUp)
	{
		SetLevel(TurretLevel + 1);
	}
	else
	{
		PurchasedUpgrades = (1 << Index - 1) | PurchasedUpgrades;
	}
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	Refresh();
}

function SetLevel( byte NewLevel )
{
	if(NewLevel != TurretLevel)
	{
		TurretLevel = NewLevel;
		St_Base(Owner).SetLevelUp(TurretLevel); //trigger the turret to upgrade/downgrade
	}
}

simulated function SetLevelUpgrade()
{
	local int NextLevel;
	NextLevel = TurretLevel + 1;

	if(LevelInfos.Length > NextLevel)
	{
		UpgradeInfos[EUpLevelUp].Icon = LevelInfos[NextLevel].Icon;
		UpgradeInfos[EUpLevelUp].DrawColor = LevelInfos[NextLevel].DrawColor;
		UpgradeInfos[EUpLevelUp].Cost = LevelInfos[NextLevel].Cost;
		UpgradeInfos[EUpLevelUp].Description = LevelInfos[NextLevel].Description;
		UpgradeInfos[EUpLevelUp].bIsEnabled = True;
	}
	else
	{
		UpgradeInfos[EUpLevelUp].bIsEnabled = False;
	}
}

simulated function int CalcAvailableUpgrades()
{
	local int i;

	AvailableUpgrades.Length = 0;
	if(UpgradeInfos[EUpLevelUp].bIsEnabled)
		AvailableUpgrades.AddItem(EUpLevelUp);
	for(i = 1; i < TotalUpgrades; i++)
	{
		if(MeetsRequirements(i))
		{
			AvailableUpgrades.AddItem(i);
		}
	}

	return AvailableUpgrades.Length;
}

simulated function bool MeetsRequirements(int Index)
{
	//checks in order: Upgrade enabled, upgrade not purchased, meets level requirement, meets upgrades requirement
	return UpgradeInfos[Index].bIsEnabled && !HasUpgrade(Index) && TurretLevel >= UpgradeInfos[Index].RequiredLevel && ((UpgradeInfos[Index].RequirementMask == 0) || ((UpgradeInfos[Index].RequirementMask & PurchasedUpgrades) == UpgradeInfos[Index].RequirementMask));
}

simulated function UpdateUpgrades();
simulated function Timer();
simulated function ModifyDamageTaken( out int InDamage, optional class<DamageType> DamageType, optional Controller InstigatedBy );
simulated function ModifyDamageGiven( out int InDamage, optional KFPawn_Monster MyKFPM, optional out class<KFDamageType> DamageType, optional int HitZoneIdx );

defaultproperties
{
	/*
	EUpLevelUp, //Dont mask
	EUpRangeA, //mask 1
	EUpRangeB, //mask 2
	EUpAccuracyA, //mask 4
	EUpAccuracyB, //mask 8
	EUpHeadshots, //mask 16
	EUpHomingMissiles, //mask 32
	EUpAutoRepair, //mask 64
	EUpFireDamage, //mask 128
	EUpDamageReduceA, //mask 256
	EUpDamageReduceB, //mask 512
	*/

	UpgradeInfos(EUpLevelUp)={(
		Icon=Texture2D'Turret_TF2.HUD.Favorite_Perk_Icon',
		Cost=2000,
		Title="Turret Level",
		Description="Upgrade to the next turret level, higher base stats and more upgrades",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpRangeA)={(
		Icon=Texture2D'Turret_TF2.HUD.Favorite_Perk_Icon',
		Cost=1000,
		Title="Range 1",
		Description="First range increase",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpRangeB)={(
		Icon=Texture2D'Turret_TF2.HUD.No_Perk_Icon',
		Cost=2000,
		RequirementMask=1,
		Title="Range 2",
		Description="Second range increase",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpAccuracyA)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Berserker',
		Cost=1000,
		Title="Accuracy 1",
		Description="Increases bullet accuracy",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpAccuracyB)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Demolition',
		Cost=2000,
		RequirementMask=4,
		Title="Accuracy 2",
		Description="Increases bullet accuracy even more",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpHeadshots)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Commando',
		Cost=3000,
		RequirementMask=8,
		Title="Head Popper",
		Description="Turret will aim for it's target head (if it has one)",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpHomingMissiles)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Firebug',
		Cost=2000,
		RequirementMask=4,
		Title="Homing Missiles",
		Description="Missiles will track their target after firing",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpAutoRepair)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Gunslinger',
		Cost=3000,
		Title="Auto Repair",
		Description="Repairs health over time",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpFireDamage)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Medic',
		Cost=2000,
		Title="Fire Damage",
		Description="Mixes fire rounds in with the regular bullets",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpDamageReduceA)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Medic',
		Cost=2000,
		Title="Large Zed damage reduction",
		Description="Reduces damage taken from large Zeds",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpDamageReduceB)={(
		Icon=Texture2D'Turret_TF2.HUD.Perk_Medic',
		Cost=2000,
		Title="Husk damage reduction",
		Description="Reduces damage taken from Husks",
		bIsEnabled=False
	)}
}