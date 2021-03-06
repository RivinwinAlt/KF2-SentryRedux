// Default functions and variables for each turret types upgrade tree
// Also handles current level and level ups

class ST_Upgrades_Base extends ReplicationInfo;

// Max number of enums (and upgrades) is 32 not including EUpLevelUp and TotalUpgrades
// Order of enums is order in menu
enum UpgradeEnums
{
	EUpLevelUp,
	EUpPrimaryDamage,
	EUpSecondaryDamage,
	EUpHealthUp,
	EUpFireRate,
	EUpRange,
	EUpAccuracy,
	EUpTurnRadiusA,
	EUpTurnRadiusB,
	EUpTurnRadiusC,
	EUpDamageReduceA,
	EUpDamageReduceB,
	EUpDamageReduceC,
	EUpPrimaryAmmoUp,
	EUpSecondaryAmmoUp,
	EUpSpecialAmmoUp,
	EUpHeadshots,
	EUpWeaponBehaviour,
	EUpAutoRepair,
	EUpPrimaryDamageType,
	EUpSecondaryDamageType,
	EUpSpecialDamageType,
	EUpAggroUp,

	TotalUpgrades // As int represents the total number of upgrades available
};

struct LevelInfo
{
	var int IconIndex;				// Used to reference an array of textures in ST_GUIStyle
	var Color DrawColor;			// Color to tint the icon

	var KFCharacterInfo_Monster TurretArch;

	var string Title, Description;
	var int Cost, BaseDamage[`NUM_WEAPONS], BaseMaxHealth, BaseMaxAmmoCount[`NUM_WEAPONS];
	var array<UpgradeEnums> RequiredUpgrades;
	var float BaseRoF[`NUM_WEAPONS], BaseTurnRadius, BaseAccuracyMod[`NUM_WEAPONS], BaseSightRadius;

	structdefaultproperties
	{
		IconIndex=`ICON_DEFAULT	// Defaults to "missing texture" icon
		DrawColor = (R=220, G=220, B=0, A=255) // Default color is yellow
		BaseTurnRadius = 0.6f
		BaseAccuracyMod = 0.06f
		BaseSightRadius = 2200.0f
	}
};
var array<LevelInfo> LevelInfos;	// Holds all upgrades in an iterable list

struct UpgradeInfo
{
	var bool bIsEnabled;

	var int IconIndex;				// Used to reference an array of textures in ST_GUIStyle
	var Color DrawColor;
	var bool bBuffUpgrade;			// Currently not used, in reserve for menu rendering logic
	var string Title, Description;

	var int Cost, InitialCost;
	var byte RequiredLevel;			// Minimum turret level for upgrade to show in menu
	var array<UpgradeEnums> RequiredUpgrades, ExcludedUpgrades;

	var int Value;					// Reserved for integer math to increase speed during upgrade checks
	var float FValue;				// Reserved for floating point math during upgrade checks
	var float BValue;				// Base value set by modder
	var float ValueModifier;		// Exposed in config file to allow effect scaling by end-user

	var bool bRebuyable;			// Set to true in order for the upgrade to have multiple levels
	var byte CurrentLevel;			// Only use if bRebuyable is true, slower than HasUpgrade()
	var byte NumUpgradeLevels;		// The max upgrade level

	structdefaultproperties
	{
		IconIndex=`ICON_DEFAULT	// A "missing texture" icon by default
		RequiredLevel = 0
		DrawColor = (R=255, G=255, B=255, A=255)	// Defaults to white icon
		ValueModifier = 1.0f
		bIsEnabled = False			// Will not show in menu unless enabled in extended upgrades class
		NumUpgradeLevels = 1
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
var byte Armor, MaxArmor; // Pulled from KFPawn_Human

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
		TurretLevel = 0; // This is a replicated value that triggers synchronization for clients
		TurretLevelChange(); // Initialize turret variables on server
	}
}

// Function to attach Self to pawn's variable
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
	TurretOwner.DoshValue += UpgradeInfos[Index].Cost;
	if(Index == EUpLevelUp)
	{
		// If the turret level upgrade was purchased
		TurretLevel++;
		TurretLevelChange();
	}
	else
	{
		// If any other upgrade was purchased
		PurchasedUpgrades = (1 << Index - 1) | PurchasedUpgrades; // This one line kicks off replication and state synchronization for the proxy actors
		
		// While these don't need to be here for the server, they will need to be implemented here for single player and hosted games
		CalcAvailableUpgrades();
		UpdateUpgrades();
	}
}

// Updates owner turret's variables to reflect current int TurretLevel
simulated function TurretLevelChange()
{
	// Initialize mesh and materials (Also Resets AI)
	TurretOwner.UpdateDisplayMesh();

	// Operations to perform when turret is first initialized
	if(!bInitialized)
	{
		TurretOwner.Health = LevelInfos[TurretLevel].BaseMaxHealth;
		InitializeUpgrades();
		SetTimer(TimerPeriod, true, 'UpgradesTimer');
	}
	
	// Update level-up upgrade info
	SetLevelUpgrade();

	// Update turret stats
	UpdateUpgrades();

	if(!bInitialized)
	{
		bInitialized = true;
	}
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
	if(WorldInfo.NetMode == NM_DedicatedServer)
		return;

	// Empty current list of upgrades
	AvailableUpgrades.Length = 0;

	// Handle the level-up upgrade seperately because SetLevelUpgrade() handles calculating its requirements
	if(UpgradeInfos[EUpLevelUp].bIsEnabled)
		AvailableUpgrades.AddItem(EUpLevelUp);

	// Iterate through rest of upgrades
	// TODO: this could be sped up by using foreach and making MeetsRequirements() a member of UpgradeInfo
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
// TODO: replace logic with: build a local bit mask and then OR it with PurchasedUpgrades to get a boolean pass or fail (optimization)
simulated function bool MeetsRequirements(int Index)
{
	local bool passed;
	local UpgradeEnums TempIndex;

	// Check upgrade is enabled, not purchased, turret level meets requirement, repeatable upgrades havent been maxed out
	if(!UpgradeInfos[Index].bIsEnabled || (HasUpgrade(Index) && !UpgradeInfos[Index].bRebuyable) || UpgradeInfos[Index].RequiredLevel > TurretLevel || UpgradeInfos[Index].CurrentLevel >= UpgradeInfos[Index].NumUpgradeLevels)
		return false;

	// Initialize default value before checks
	passed = true;

	// Check required upgrades array
	foreach UpgradeInfos[Index].RequiredUpgrades(TempIndex)
	{
		if(!HasUpgrade(TempIndex))
			passed = false;
	}

	// Check mutualy exclusive upgrades array
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

		// Set Cost to the Initial cost value
		UpgradeInfos[i].Cost = UpgradeInfos[i].InitialCost;
	}

	TurretOwner.AmmoCount[EPrimaryFire] = TurretOwner.MaxAmmoCount[EPrimaryFire] * TurretOwner.Settings.repStartAmmo;
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
	for(i = 0; i < `NUM_WEAPONS; i++) // Iterate through the 3 firemodes to access the associated static arrays
	{
		TurretOwner.AccuracyMod[i] = LevelInfos[TurretLevel].BaseAccuracyMod[i];
		TurretOwner.RoF[i] = LevelInfos[TurretLevel].BaseRoF[i];
		TurretOwner.Damage[i] = LevelInfos[TurretLevel].BaseDamage[i];
		TurretOwner.MaxAmmoCount[i] = LevelInfos[TurretLevel].BaseMaxAmmoCount[i];			
	}
	TurretOwner.HealthMax = LevelInfos[TurretLevel].BaseMaxHealth;
	TurretOwner.SetTurnRadius(LevelInfos[TurretLevel].BaseTurnRadius);
	TurretOwner.SetSightRadius(LevelInfos[TurretLevel].BaseSightRadius);
}

// Armor calculations by FluX
simulated function ShieldAbsorb(out int InDamage)
{
	local int AbsorbedDmg;

	if(Armor < 1)
		return;

	AbsorbedDmg = Min(Round(0.5 * InDamage), Armor);
	Armor -= Max(AbsorbedDmg * 0.7, 1);
	InDamage = Max(InDamage - AbsorbedDmg, 1);
}

simulated function ShieldReflect(out int InDamage, class<DamageType> InDamageType, Controller InstigatedBy)
{
	local int AbsorbedDmg;

	if(Armor < 1)
		return;

	AbsorbedDmg = Min(Round(0.5 * InDamage), Armor);
	Armor -= Max(AbsorbedDmg * 0.7, 1);
	InDamage = Max(InDamage - AbsorbedDmg, 1);

	// TODO: Deal damage to InstigatedBy.Pawn here
}

simulated function UpgradesTimer(); // Executed on a timer
simulated function ModifyDamageTaken( out int InDamage, optional class<DamageType> InDamageType, optional Controller InstigatedBy );
simulated function ModifyDamageGiven( out int InDamage, optional Actor HitActor, optional out class<KFDamageType> OutDamageType, optional int HitZoneIdx );

defaultproperties
{
	bAlwaysRelevant = true		// Replicates to all clients to ensure synchronization. May not be necessary
	StartingAmmoModifier = 0.2f // TODO: Move to config
	TurretLevel = 255			// Start on anything but 0 so that replication immediatly leads to state synchronization
	TimerPeriod = 3.0f			// Time between calls to UpgradesTimer()

	AmmoInfos(EPrimaryFire) = {(
		IconIndex = `ICON_DEFAULT,
		CostPerRound = 1
	)}

	AmmoInfos(ESecondaryFire) = {(
		IconIndex = `ICON_DEFAULT,
		CostPerRound = 5
	)}

	AmmoInfos(ESpecialFire) = {(
		IconIndex = `ICON_DEFAULT,
		CostPerRound = 25
	)}

	UpgradeInfos(EUpLevelUp)={( // Never override this SPECIFIC upgrade, it is just a container for what you put in LevelInfos[]
		InitialCost=9876,
		Title="Turret Level",
		Description="Upgrade to the next turret level to get higher base stats and more upgrade options",
		bIsEnabled=False // Dont even try to enable this. Its automatically enabled when theres a levelup available.
	)}

		UpgradeInfos(EUpPrimaryDamage)={(
		InitialCost=750,
		bRebuyable = True,
		Title="Primary Damage Up",
		Description="Increase Primary Damage by 20%",
		BValue=1.2f, // cos(360 / 2)
		bIsEnabled=False
	)}

		UpgradeInfos(EUpSecondaryDamage)={(
		InitialCost=1000,
		bRebuyable = True,
		Title="Secondary Damage Up",
		Description="Increase Secondary Damage by another 20%",
		BValue=1.2f, // cos(360 / 2)
		bIsEnabled=False
	)}

		UpgradeInfos(EUpHealthUp)={(
		InitialCost=600,
		bRebuyable = True,
		Title="Health Up",
		Description="Max Health Increased by 30%",
		BValue=1.3f, // cos(360 / 2)
		bIsEnabled=False
	)}

		UpgradeInfos(EUpFireRate)={(
		InitialCost=600,
		bRebuyable = True,
		Title="Fire Rate Up",
		Description="Rate of Fire Increased by another 20%",
		BValue=0.80f, // cos(360 / 2)
		bIsEnabled=False
	)}

	UpgradeInfos(EUpRange)={(
		InitialCost=200,
		bRebuyable = True,
		Title="Eagle Eye",
		Description="Increase range by 25%",
		BValue=1.25f,
		bIsEnabled=False
	)}

	UpgradeInfos(EUpAccuracy)={(
		InitialCost=200,
		bRebuyable = True,
		Title="Iron Sights",
		Description="Reduce primary weapon spread by 25%",
		BValue=0.75f,
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpHeadshots)={(
		InitialCost=700,
		RequiredUpgrades=(EUpAccuracy),
		Title="Head Popper",
		Description="Turret will aim for it's target's head (if it has one)",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpWeaponBehaviour)={(
		InitialCost=500,
		RequiredUpgrades=(EUpAccuracy),
		Title="Homing Missiles",
		Description="Missiles will track their target after firing",
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpAutoRepair)={(
		InitialCost=1000,
		Title="Auto Repair",
		Description="Heals turret over time",
		BValue=10.0f,
		bIsEnabled=False
	)}
	
	UpgradeInfos(EUpPrimaryDamageType)={(
		InitialCost=500,
		Title="Fire Damage",
		Description="Deals fire damage every ... attacks",
		bIsEnabled=False
	)}

	UpgradeInfos(EUpDamageReduceA)={(
		InitialCost=500,
		Title="Large Zed damage reduction",
		Description="Reduces damage taken from large Zeds by 40%",
		BValue=0.6f,
		bIsEnabled=False
	)}

	UpgradeInfos(EUpDamageReduceB)={(
		InitialCost=500,
		Title="Fire Armor",
		Description="Reduces all fire damage taken by 40%",
		BValue=0.6f,
		bIsEnabled=False
	)}

	UpgradeInfos(EUpTurnRadiusA)={(
		InitialCost=1000,
		Title="Turn Radius",
		Description="Increases turn radius to 160 degrees",
		BValue=0.1736f, // cos(160 / 2)
		bIsEnabled=False
	)}

	UpgradeInfos(EUpTurnRadiusB)={(
		InitialCost=1500,
		RequiredUpgrades=(EUpTurnRadiusA),
		Title="Turn Radius +",
		Description="Increases turn radius to 210 degrees",
		BValue=-0.2588f, // cos(210 / 2)
		bIsEnabled=False
	)}

	UpgradeInfos(EUpTurnRadiusC)={(
		InitialCost=2000,
		RequiredUpgrades=(EUpTurnRadiusB),
		Title="Zero Turn Mower",
		Description="Allows the turret to turn in any direction",
		BValue=-1f, // cos(360 / 2)
		bIsEnabled=False
	)}

		UpgradeInfos(EUpPrimaryAmmoUp)={(
		InitialCost=2000,
		Title="Primary Ammo Up",
		Description="Max Ammo for Primary Weapon Increased by 40%",
		BValue=1.4f, // cos(360 / 2)
		bIsEnabled=False
	)}

		UpgradeInfos(EUpSecondaryAmmoUp)={(
		InitialCost=2000,
		Title="Secondary Ammo Up",
		Description="Max Ammo for Secondary Weapon Increased by 40%",
		BValue=1.4f, // cos(360 / 2)
		bIsEnabled=False
	)}
}