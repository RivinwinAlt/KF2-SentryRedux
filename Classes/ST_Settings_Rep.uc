// Singleton server object replicated to all clients

Class ST_Settings_Rep extends ReplicationInfo
	transient
	config(SentryRedux);

`define CONFIG_VERSION 2

var config byte ConfigVersion;
var config float SellMultiplier, MercySellMultiplier, PreviewRotationRate;
var config int MaxPlayerTurrets, TurretHealthTickDown;
var config int MaxMapTurrets;

var transient int NumPlayerTurrets; // client variable, do not reference on server
var transient int NumMapTurrets;
var transient array<ST_Turret_Base> AllTurrets; // Only populated server side, use the Overlay array to reference turrets on client

var float repPreviewRot, repSellMult, repMercySell; // Non-config versions to insulate clients.
var int repHealthTick, repMaxPlayer, repMaxMap;

struct TurretBuildInfo
{
	var class<ST_Turret_Base> TurretClass;
	var int BuildCost;
	var int BuildRadius;

	structdefaultproperties
	{
		BuildRadius = 125;
	}
};
var array<TurretBuildInfo> PreBuildInfos;

replication
{
	if(bNetDirty)
		repSellMult, repMercySell, repMaxPlayer, repMaxMap, NumMapTurrets, repHealthTick;
}

// Ensures there is always exactly one spawned instance of this class on the server.
simulated static final function ST_Settings_Rep GetSettings(WorldInfo Level)
{
	local ST_Settings_Rep SingletonRef;
	
	//Search through spawned actors for an existing instance of this class
	foreach Level.DynamicActors(class'ST_Settings_Rep', SingletonRef)
	{
		if(SingletonRef != None)
			return SingletonRef;
	}

	// If server and none exists spawn a new instance
	if(Level.NetMode != NM_Client)
	{
		SingletonRef = Level.Spawn(class'ST_Settings_Rep');
		return SingletonRef;
	}

	return None;
}

function PostBeginPlay()
{
	local KFGameInfo GameInfo;

	// Replace scriptwarning spewing DialogManager.
	GameInfo = KFGameInfo(WorldInfo.Game);
	if(GameInfo != None)
	{
		if(GameInfo.DialogManager != None)
		{
			if(GameInfo.DialogManager.Class == Class'KFDialogManager')
			{
				GameInfo.DialogManager.Destroy();
				GameInfo.DialogManager = Spawn(class'ST_DialogManager');
			}
		}
		else if(GameInfo.DialogManagerClass == Class'KFDialogManager')
			GameInfo.DialogManagerClass=class'ST_DialogManager';
	}

	if(WorldInfo.NetMode != NM_DedicatedServer)
		PlayerCountTurrets();

	UpdateConfig();
}

function SyncClientVariables()
{
	repSellMult = SellMultiplier;
	repMercySell = MercySellMultiplier;
	repMaxPlayer = MaxPlayerTurrets;
	repMaxMap = MaxMapTurrets;
	repHealthTick = TurretHealthTickDown;
}

// These functions are intentionally asynchronous and unclamped to allow smooth networking
// It should be possible to go beyond the max map turrets if two players place within the same network tick, No real fix, minor bug expected, does not effect turrets per player which is stored locally.
function TurretCreated(optional ST_Turret_Base NewTurret)
{
	++NumMapTurrets;

	if(NewTurret != none)
	{
		if(AllTurrets.Find(NewTurret) < 0) // Didn't find it in the array
		{
			AllTurrets.AddItem(NewTurret);
		}
	}
}
function TurretDestroyed(optional ST_Turret_Base DestroyedTurret)
{
	--NumMapTurrets;

	if(DestroyedTurret != none)
	{
		AllTurrets.RemoveItem(DestroyedTurret);
	}
}

// Make this run once every long while to support big sprawling high wave servers
// TODO: Split into stages that run a second or so apart
function CleanServer()
{
	local ST_AI_Base tempAI;
	local ST_Upgrades_Base tempUpgradeObj;
	local ST_Turret_Base tempTurret;

	// Iterate through all actors on server and delete/cleanup 
	foreach WorldInfo.AllControllers(class'ST_AI_Base', tempAI)
	{
		// Look for detached or extra AI
	}
	foreach WorldInfo.AllActors(class'ST_Upgrades_Base', tempUpgradeObj)
	{
		// Look for detached or extra Upgrades
	}
	foreach WorldInfo.AllPawns(class'ST_Turret_Base', tempTurret)
	{
		// Look for uninitialized turrets, check turret playerowners and such.
	}
}
function CleanAllTurrets()
{
	local int i;

	// TODO: weed out duplicates: maybe sort it first then compare element n to element n+1
	for(i = 0; i < AllTurrets.Length; ++i)
	{
		if(!AllTurrets[i].IsAliveAndWell())
		{
			AllTurrets.Remove(i, 1);
			--i;
		}
	}
}
function int CountTurrets() // TODO: implement a flag that helps us run CleanServer() only if this function doesnt resolve the issue
{
	local ST_Turret_Base tempTurret;
	local int i;

	i = 0;
	foreach WorldInfo.AllPawns(class'ST_Turret_Base', tempTurret)
	{
		if( tempTurret.IsAliveAndWell())
			++i;
	}

	/*if(i != AllTurrets.Length)
	{
		RebuildAllTurrets();
	}*/

	return i;
}
simulated function PlayerCountTurrets()
{
	local ST_Turret_Base T;
	local PlayerController PC;

	PC = GetALocalPlayerController();

	NumPlayerTurrets = 0;
	foreach WorldInfo.AllPawns(class'ST_Turret_Base', T)
	{
		if(T.OwnerController == PC && T.IsAliveAndWell())
			++NumPlayerTurrets;
	}
}
function RebuildAllTurrets()
{
	local ST_Turret_Base tempTurret;

	AllTurrets.Length = 0;
	foreach WorldInfo.AllPawns(class'ST_Turret_Base', tempTurret)
	{
		if(tempTurret.IsAliveAndWell())
			AllTurrets.AddItem(tempTurret);
	}
}

simulated function bool CheckNumMapTurrets(optional class<ST_Turret_Base> TurretClass)
{
	if(NumMapTurrets < repMaxMap /*|| if(ADMIN_AUTHORITY)*/ )
		return true;
	return false;
}

simulated function bool CheckNumPlayerTurrets(class<ST_Turret_Base> TurretClass)
{
	if((NumPlayerTurrets < repMaxPlayer ) /*|| if(ADMIN_AUTHORITY)*/ )
		return true;
	return false;
}

simulated function TurretBuildInfo GetBuildInfo(class<ST_Turret_Base> FindClass)
{
	local int index;

	index = PreBuildInfos.Find('TurretClass', FindClass);
	if(index > -1)
		return PreBuildInfos[index];

	return PreBuildInfos[0]; // Default behavior
}

simulated function int GetBuildCost(class<ST_Turret_Base> FindClass)
{
	local TurretBuildInfo BuildInfo;

	BuildInfo = GetBuildInfo(FindClass);
	if(BuildInfo.TurretClass != none)
		return BuildInfo.BuildCost;

	return 0; // Default behavior
}

// This function creates a config file if it didn't already exist, change the value of CONFIG_VERSION to force a refresh
final function UpdateConfig()
{
	if(Default.ConfigVersion != `CONFIG_VERSION)
	{
		Default.TurretHealthTickDown = 35;
		Default.SellMultiplier = 0.7f;
		Default.MercySellMultiplier = 1.0f;
		Default.MaxPlayerTurrets = 3;
		Default.MaxMapTurrets = 50;
		Default.ConfigVersion = `CONFIG_VERSION;
		Default.PreviewRotationRate = 8.0f;
		StaticSaveConfig();
	}
	SyncClientVariables();
}

//TODO Expose net update frequency to config
defaultproperties
{
	// The order of this list will determine the order of the list when shown in-game
	PreBuildInfos.Add((TurretClass = class'ST_Turret_TF2', BuildCost = 500))

   //NetUpdateFrequency = 4.000000
}
