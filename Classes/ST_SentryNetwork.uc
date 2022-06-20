// Each Player Actor actually has their own object of this type on both the server and client as a simulated proxy.
class ST_SentryNetwork extends ReplicationInfo
	dependson(ST_Upgrades_Base); // Gives access to upgrade enums;

var ST_Turret_Base TurretOwner;
var repnotify PlayerController PlayerOwner;

var transient ST_Settings_Rep Settings;
var transient byte SendIndex;
var transient ST_GUIController GUIController;
var transient bool bWasInitAlready, bActiveTimer;

replication
{
	// Variables the server should send ALL clients.
	if( bNetDirty )
		TurretOwner, PlayerOwner;
}

simulated event ReplicatedEvent( name VarName )
{
	//if( TurretOwner!=None && PlayerOwner!=None && !bWasInitAlready)
	if(VarName == 'PlayerOwner')
	{
		bWasInitAlready = true;
		SetOwner(PlayerOwner);
	}
	else
	{
		super.ReplicatedEvent(VarName);
	}
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);
}

static final function ST_SentryNetwork GetNetwork(PlayerController PC)
{
	local ST_SentryNetwork SN;
	
	foreach PC.ChildActors(class'ST_SentryNetwork', SN)
		break;
	if(SN == None)
		SN = PC.Spawn(class'ST_SentryNetwork', PC);
	SN.PlayerOwner = PC;
	
	return SN;
}

simulated reliable client function ClientOpenMenu()
{
	if(WorldInfo.NetMode != NM_Client)
		return;
	if( GUIController==None )
		GUIController = Class'ST_GUIController'.Static.GetGUIController(PlayerOwner);
	GUIController.TurretOwner = TurretOwner;
	GUIController.NetworkObj = Self;
	GUIController.OpenMenu(class'UI_SentryMenu');
}

simulated reliable client function ClientCloseMenu()
{
	if(WorldInfo.NetMode != NM_Client)
		return;
	if( GUIController==None )
		GUIController = Class'ST_GUIController'.Static.GetGUIController(PlayerOwner);
	GUIController.CloseMenu(none, true); // Closes all open menus
}

function SetInfo( ST_Turret_Base T, PlayerController PC)
{
	TurretOwner = T;
	if(Owner != PC)
	{
		SetOwner(PC);
	}
}

reliable server function PerformPurchase(int Index)
{
    PlayerOwner.PlayerReplicationInfo.Score -= TurretOwner.UpgradesObj.UpgradeInfos[Index].Cost;
    TurretOwner.UpgradesObj.BoughtUpgrade(Index);
}

reliable server function PerformAmmoPurchase(int Index, int Amount)
{
    PlayerOwner.PlayerReplicationInfo.Score -= Amount * TurretOwner.UpgradesObj.AmmoInfos[Index].CostPerRound;
    TurretOwner.AddAmmo(Index, Amount);
}

reliable server function SellTurret()
{
    TurretOwner.TryToSellTurret(PlayerOwner);
}

reliable server function ClosedMenu()
{
	GUIController = none;
}

simulated function Destroyed()
{
	if(WorldInfo.NetMode != NM_Client && GUIController != none)
		ClientCloseMenu();

	super.Destroyed();
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bAlwaysRelevant=False
}
