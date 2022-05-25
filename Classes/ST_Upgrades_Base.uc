// Default functions and variables for each turret types upgrade tree
// Also handles current level and level ups

class ST_Upgrades_Base extends ReplicationInfo;

//max number of enums (and upgrades) is 32 not including EUpLevelUp and TotalUpgrades
//order of enums is order in menu
enum UpgradeEnums
{
	EUpLevelUp,
	EUpRangeA,
	EUpRangeB,
	EUpAccuracyA,
	EUpAccuracyB,
	EUpHeadshots,
	EUpHomingMissiles,
	EUpAutoRepair,
	EUpFireDamage,
	EUpDamageReduceA,
	EUpDamageReduceB,
	EUpTurnRadiusA,
	EUpTurnRadiusB,
	EUpTurnRadiusC,

	TotalUpgrades // As int represents the total number of upgrades available
};

struct LevelInfo
{
	var int IconIndex; // Used to reference an array of textures in ST_GUIStyle
	var Color DrawColor;

	var KFCharacterInfo_Monster TurretArch;

	var string Title, Description;
	var int Cost, BaseDamage[3], BaseMaxHealth;
	var array<UpgradeEnums> RequiredUpgrades;
	var float BaseRoF, BaseTurnRadius, BaseAccuracyMod, BaseSightRadius;

	var int BaseMaxAmmoCount[3];
	var SoundCue FiringSounds[3];

	structdefaultproperties
	{
		IconIndex=`ICON_DEFAULT;
		DrawColor = (R=220,G=220,B=0,A=255); //Default color is gold
		BaseTurnRadius = 0.6f;
		BaseAccuracyMod = 0.06f;
		BaseSightRadius = 2200.0f
		BaseMaxAmmoCount[0] = 0;	//Disabled by default
		BaseMaxAmmoCount[1] = 0;	//Disabled by default
		BaseMaxAmmoCount[2] = 0;	//Disabled by default
	}
};
var array<LevelInfo> LevelInfos;	//Holds all upgrades in an iterable list

struct UpgradeInfo
{
	var int IconIndex;
	var Color DrawColor;

	var int Cost;
	var byte RequiredLevel;			// Minimum turret level for upgrade to show in menu
	var array<UpgradeEnums> RequiredUpgrades, ExcludedUpgrades;
	var int Value;					// Reserved for integer math to increase speed during upgrade checks
	var float FValue;				// Reserved for floating point math during upgrade checks
	var float BValue;				// Base value in code
	var float ValueModifier;		// Exposed in config file to allow effect scaling by user
	var string Title, Description;
	var bool bIsEnabled;

	structdefaultproperties
	{
		IconIndex=`ICON_DEFAULT;
		RequiredLevel = 0;
		DrawColor = (R=255, G=255, B=255, A=255);	// Defaults to white icon
		ValueModifier = 1.0f;
		bIsEnabled = False;			// Will not show in menu unless enabled in extended upgrades class
	}
};
var array<UpgradeInfo> UpgradeInfos;

struct AmmoInfo
{
	var int IconIndex;
	var Color DrawColor;

	var int CostPerRound;
	var int BuyAmount;

	structdefaultproperties
	{
		IconIndex=`ICON_DEFAULT;
		DrawColor = (R=255, G=255, B=255, A=255);	//Defaults to white icon
		BuyAmount = 250;
	}
};
var AmmoInfo AmmoInfos[3];

var array<int> AvailableUpgrades;

enum FireTypeEnums // Used to easily access 
{
	EPrimaryFire,
	ESecondaryFire,
	ESpecialFire,

	ENumFireTypes // Used as int to cycle through fire types
};

var repnotify byte TurretLevel;
var repnotify int PurchasedUpgrades;
var byte InitState;
var repnotify ST_Turret_Base TurretOwner;
var float StartingAmmoModifier, TimerPeriod;
var bool bInitialized;

//Only set on client, used to notify changes
var transient UIR_UpgradesList LocalMenu;

replication
{
	if(bNetDirty)
		TurretOwner, PurchasedUpgrades, TurretLevel;
}

simulated event ReplicatedEvent(name VarName)
{
	switch( VarName )
	{
	case 'TurretOwner':
		LinkTurret();
		// No break; here so that TurretLevelChange() is executed as well
	case 'TurretLevel':
		if(TurretOwner != none)
			TurretLevelChange();
		break;
	case 'PurchasedUpgrades':
		if(TurretOwner != none)
		{
			CalcAvailableUpgrades();
			UpdateUpgrades();
		}
		break;
	}
}

// Server function to attach pawn
function SetTurretOwner(ST_Turret_Base T)
{
	if(T != none && T != TurretOwner)
	{
		TurretOwner = T;
		TurretLevel = 0; // This is a replicated value that triggers TurretLevelChange() for clients
		TurretLevelChange(); // Initialize turret variables
	}
}

// Server function to attach Self to pawn's variable
simulated function LinkTurret()
{
	if(TurretOwner != none)
		TurretOwner.UpgradesObj = Self;
}

// Check if upgrade has been purchased
simulated final function bool HasUpgrade(byte Index)
{
	return ((1 << Index - 1) & PurchasedUpgrades) > 0; // subtract 1 from Index because EUpLevelUp doesnt store to PurchasedVariables
}

// Does not simulate on proxy-actor, TurretLevel and PurchasedUpgrades are replicated and trigger events on client
// This function is called from the networking object inside a replicated server function
final function BoughtUpgrade(int Index)
{
	TurretOwner.SentryWorth += UpgradeInfos[Index].Cost;
	if(Index == EUpLevelUp)
	{
		// If the turret level upgrade was purchased
		TurretLevel++;
		TurretLevelChange();
	}
	else
	{
		// If any other upgrade was purchased
		PurchasedUpgrades = (1 << Index - 1) | PurchasedUpgrades;
		CalcAvailableUpgrades();
		UpdateUpgrades();
	}
}

// Updates owner turret's variables to reflect current int TurretLevel
simulated function TurretLevelChange()
{
	if(WorldInfo.NetMode != NM_Client)
	{
		TurretOwner.bRecentlyBuilt = true;
		SetTimer(0.5, false, 'UnsetBuilt');
	}

	// Operations to perform when turret is first initialized
	if(!bInitialized)
	{
		TurretOwner.Health = LevelInfos[TurretLevel].BaseMaxHealth;
		InitializeUpgrades();
		SetTimer(TimerPeriod, true, 'UpgradesTimer');
	}

	// Initialize mesh and materials (Resets AI)
	TurretOwner.UpdateDisplayMesh();

	// Update level-up upgrade info
	SetLevelUpgrade();

	// Update turret stats
	UpdateUpgrades();

	// Set initialization flag
	bInitialized = true;
}

// Helper function for server to clear build flag
function UnsetBuilt()
{
	TurretOwner.bRecentlyBuilt = false;
}

simulated function SetLevelUpgrade()
{
	local int NextLevel;

	NextLevel = TurretLevel + 1;
	if(LevelInfos.Length > NextLevel) // If there is another upgrade to purchase
	{
		UpgradeInfos[EUpLevelUp].IconIndex = LevelInfos[NextLevel].IconIndex;
		UpgradeInfos[EUpLevelUp].DrawColor = LevelInfos[NextLevel].DrawColor;
		UpgradeInfos[EUpLevelUp].Cost = LevelInfos[NextLevel].Cost;
		UpgradeInfos[EUpLevelUp].Description = LevelInfos[NextLevel].Description;
		UpgradeInfos[EUpLevelUp].bIsEnabled = True;
	}
	else // Else disable the upgrade
	{
		UpgradeInfos[EUpLevelUp].bIsEnabled = False;
	}

	// Update the list of available upgrades for menu
	CalcAvailableUpgrades();
}

// Updates the dynamic array of available upgrades for menu and triggers menu update
simulated function CalcAvailableUpgrades()
{
	local int i;

	// Exit function if called on server to save unnecesary compute time
	if(WorldInfo.NetMode != NM_Client)
		return;

	// Empty current list of upgrades
	AvailableUpgrades.Length = 0;

	// Handle the level-up upgrade seperately because SetLevelUpgrade() handles calculating its requirements
	if(UpgradeInfos[EUpLevelUp].bIsEnabled)
		AvailableUpgrades.AddItem(EUpLevelUp);

	// Iterate through rest of upgrades
	for(i = 1; i < TotalUpgrades; i++) // TotalUpgrades must be the last value of UpgradeEnums
	{
		if(MeetsRequirements(i))
		{
			AvailableUpgrades.AddItem(i);
		}
	}

	// Trigger menu update
	UpdateLinkedMenu();
}

// Helper function to check upgrade requirements to be purchased
// TODO: Add mutually-exlusive check
simulated function bool MeetsRequirements(int Index)
{
	local bool passed;
	local UpgradeEnums TempIndex;

	// Check upgrade is enabled, not purchased, turret level meets requirement
	if(!UpgradeInfos[Index].bIsEnabled || HasUpgrade(Index) || UpgradeInfos[Index].RequiredLevel > TurretLevel)
		return false;

	// Initialize default value before checks
	passed = true;

	// Check required upgrades array
	foreach UpgradeInfos[Index].RequiredUpgrades(TempIndex)
	{
		if(!HasUpgrade(TempIndex))
			passed = false;
	}

	// Check excluded upgrades array
	foreach UpgradeInfos[Index].ExcludedUpgrades(TempIndex)
	{
		if(HasUpgrade(TempIndex))
			passed = false;
	}

	return passed;
}

// If there is a linked menu object (which only occurs on the client) update upgrade list length
simulated function UpdateLinkedMenu()
{
	if(LocalMenu != none)
		LocalMenu.UpdateListLength();
}

// Runs once to initialize values in each upgrade based on configs (needs to be triggered when config values cahnge during runtime)
// TODO: Implement mina nd max values in upgrade struct and clamp FValue between them
simulated function InitializeUpgrades()
{
	local int i;

	for(i = 1; i < TotalUpgrades; i++)
	{
		// Calculate usable upgrade value as floating point
		UpgradeInfos[i].FValue = UpgradeInfos[i].BValue * UpgradeInfos[i].ValueModifier;

		// Store value to integer (for later optimization)
		UpgradeInfos[i].Value = Round(UpgradeInfos[i].FValue);
	}
}

// Cleanup
simulated function Destroyed()
{
	ClearTimer('UpgradesTimer');
	super.Destroyed();
}

simulated function UpdateUpgrades()
{
	local int i;

	// Set turret stats to the current level defaults
	for(i = 0; i < 3; i++) // Iterate through the 3 firemodes to access the associated static arrays
	{
		TurretOwner.Damage[i] = LevelInfos[TurretLevel].BaseDamage[i];
		TurretOwner.MaxAmmoCount[i] = LevelInfos[TurretLevel].BaseMaxAmmoCount[i];
		if(!bInitialized)
			TurretOwner.AmmoCount[i] = TurretOwner.MaxAmmoCount[i] * StartingAmmoModifier;
	}
	TurretOwner.RoF = LevelInfos[TurretLevel].BaseRoF;
	TurretOwner.HealthMax = LevelInfos[TurretLevel].BaseMaxHealth;
	TurretOwner.SetTurnRadius(LevelInfos[TurretLevel].BaseTurnRadius);
	TurretOwner.SetSightRadius(LevelInfos[TurretLevel].BaseSightRadius);
	TurretOwner.AccuracyMod = LevelInfos[TurretLevel].BaseAccuracyMod;
}

simulated function UpgradesTimer(); // Executed on a timer
simulated function ModifyDamageTaken( out int InDamage, optional class<DamageType> InDamageType, optional Controller InstigatedBy );
simulated function ModifyDamageGiven( out int InDamage, optional Actor HitActor, optional out class<DamageType> OutDamageType, optional int HitZoneIdx );

defaultproperties
{
	bAlwaysRelevant=true // Replicates to all clients to ensure synchronization. May not be necessary
	StartingAmmoModifier=0.2f // TODO: Move to config
	TurretLevel=250 // Can't start on 0 so that the value is replicated after being initialized in code
	TimerPeriod=3.0f // Time between calls to UpgradesTimer()

	AmmoInfos(EPrimaryFire)={(
		IconIndex=`ICON_AMMO_BULLETS,
		CostPerRound=1
	)}

	AmmoInfos(ESecondaryFire)={(
		IconIndex=`ICON_AMMO_ROCKET,
		CostPerRound=5
	)}

	AmmoInfos(ESpecialFire)={(
		CostPerRound=25
	)}

	UpgradeInfos(EUpLevelUp)={(
		Cost=9876, // Is set dynamicly in SetLevelUpgrade()
		Title="Turret Level",
		Description="Upgrade to the next turret level to get higher base stats and more upgrade options",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpRangeA)={(
		Cost=200,
		Title="Eagle Eye",
		Description="Increase range by 25%",
		BValue=1.25f,
		bIsEnabled=False
	)}

	UpgradeInfos(EUpRangeB)={(
		Cost=500,
		RequiredUpgrades=(EUpRangeA),
		Title="Eagle Eye +",
		Description="Increase range by an additional 25%",
		BValue=1.25f,
		bIsEnabled=False
	)}

	UpgradeInfos(EUpAccuracyA)={(
		Cost=200,
		Title="Iron Sights",
		Description="Reduce primary weapon spread by 25%",
		BValue=0.75f,
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpAccuracyB)={(
		Cost=500,
		RequiredUpgrades=(EUpAccuracyA),
		Title="Iron Sights +",
		Description="Reduce primary weapon spread by an additional 25%",
		BValue=0.75f,
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpHeadshots)={(
		Cost=700,
		RequiredUpgrades=(EUpAccuracyA),
		Title="Head Popper",
		Description="Turret will aim for it's target's head (if it has one)",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpHomingMissiles)={(
		Cost=500,
		RequiredUpgrades=(EUpAccuracyB),
		Title="Homing Missiles",
		Description="Missiles will track their target after firing",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpAutoRepair)={(
		Cost=1000,
		Title="Auto Repair",
		Description="Heals turret over time",
		BValue=10.0f,
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpFireDamage)={(
		Cost=500,
		Title="Fire Damage",
		Description="Deals fire damage every ... attacks",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpDamageReduceA)={(
		Cost=500,
		Title="Large Zed damage reduction",
		Description="Reduces damage taken from large Zeds by ...",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpDamageReduceB)={(
		Cost=500,
		Title="Fire Armor",
		Description="Reduces all fire damage taken by 40%",
		BValue=0.6f,
		bIsEnabled=False
	)}

	UpgradeInfos(EUpTurnRadiusA)={(
		Cost=1000,
		Title="Turn Radius",
		Description="Increases turn radius to 160 degrees",
		BValue=0.1736f, // cos(160 / 2)
		bIsEnabled=False
	)}

	UpgradeInfos(EUpTurnRadiusB)={(
		Cost=1500,
		RequiredUpgrades=(EUpTurnRadiusA),
		Title="Turn Radius +",
		Description="Increases turn radius to 210 degrees",
		BValue=-0.2588f, // cos(210 / 2)
		bIsEnabled=False
	)}

	UpgradeInfos(EUpTurnRadiusC)={(
		Cost=2000,
		RequiredUpgrades=(EUpTurnRadiusB),
		Title="Zero Turn Mower",
		Description="Allows the turret to turn in any direction",
		BValue=-1f, // cos(360 / 2)
		bIsEnabled=False
	)}
}