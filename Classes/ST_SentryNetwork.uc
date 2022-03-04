class ST_SentryNetwork extends ReplicationInfo
	dependson(ST_Upgrades_Base); // Gives access to upgrade enums;

var repnotify ST_Base TurretOwner;
var repnotify PlayerController PlayerOwner;

var transient byte SendIndex;
var transient KF2GUIController GUIController;
var transient bool bWasInitAlready, bActiveTimer;

replication
{
	// Variables the server should send ALL clients.
	if( bNetDirty )
		TurretOwner, PlayerOwner;
}

simulated event ReplicatedEvent( name VarName )
{
	if( TurretOwner!=None && PlayerOwner!=None && !bWasInitAlready)
	{
		bWasInitAlready = true;
		SetOwner(PlayerOwner);
		ClientOpenMenu();
	}
	else if(TurretOwner==None || PlayerOwner==None)
	{
		bWasInitAlready = false;
	}
}

static final function ST_SentryNetwork GetNetwork( PlayerController PC)
{
	local ST_SentryNetwork SN;
	
	foreach PC.ChildActors(class'ST_SentryNetwork', SN)
		break;
	if(SN == None)
		SN = PC.Spawn(class'ST_SentryNetwork', PC);

	return SN;
}

simulated reliable client function ClientOpenMenu()
{
	if(WorldInfo.NetMode != NM_Client)
		return;
	if( GUIController==None )
		GUIController = Class'KF2GUIController'.Static.GetGUIController(PlayerOwner);
	GUIController.TurretOwner = TurretOwner;
	GUIController.NetworkObj = Self;
	GUIController.OpenMenu(class'UI_SentryMenu');
}

simulated reliable client function ClientCloseMenu()
{
	if(WorldInfo.NetMode != NM_Client)
		return;
	if( GUIController==None )
		GUIController = Class'KF2GUIController'.Static.GetGUIController(PlayerOwner);
	GUIController.CloseMenu(none, true); // Closes all open menus
}

function SetInfo( ST_Base T, PlayerController PC)
{
	TurretOwner = T;
	PlayerOwner = PC;
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
    Destroy();
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
