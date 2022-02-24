class SentryUI_Network extends ReplicationInfo
	dependson(ST_Upgrades_Base); // Gives access to upgrade enums;

var repnotify ST_Base TurretOwner;
var repnotify PlayerController PlayerOwner;

var transient byte SendIndex;
var transient KF2GUIController GUIController;
var transient bool bWasInitAlready, bActiveTimer;

replication
{
	// Variables the server should send ALL clients.
	if( true )
		TurretOwner,PlayerOwner;
}

simulated function PostBeginPlay()
{
	PlayerOwner = PlayerController(Owner);
}

simulated event ReplicatedEvent( name VarName )
{
	if( TurretOwner!=None && PlayerOwner!=None && !bWasInitAlready)
	{
		bWasInitAlready = true;
		SetOwner(PlayerOwner);
		SetTurret(TurretOwner);
	}
	else if(TurretOwner==None && PlayerOwner==None)
	{
		bWasInitAlready = false;
	}
}

static final function SentryUI_Network GetNetwork( PlayerController PC)
{
	local SentryUI_Network G;
    
    foreach PC.ChildActors(class'SentryUI_Network',G)
        break;
    if( G==None )
        G = PC.Spawn(class'SentryUI_Network',PC);

    return G;
}

static function OpenMenuForClient( PlayerController PC, class<KFGUI_Page> Page )
{
    local SentryUI_Network G;
    
    G = GetNetwork(PC);
    G.ClientOpenMenu(Page);
}
static function CloseMenuForClient( PlayerController PC, class<KFGUI_Page> Page, optional bool bCloseAll )
{
    local SentryUI_Network G;
    
    G = GetNetwork(PC);
    G.ClientCloseMenu(Page,bCloseAll);
}

simulated reliable client function ClientOpenMenu( class<KFGUI_Page> Page )
{
    if( WorldInfo.NetMode!=NM_Client )
        return;
    if( GUIController==None )
        GUIController = Class'KF2GUIController'.Static.GetGUIController(PlayerOwner);
    GUIController.OpenMenu(Page);
}
simulated reliable client function ClientCloseMenu( class<KFGUI_Page> Page, bool bCloseAll )
{
    if( WorldInfo.NetMode!=NM_Client )
        return;
    if( GUIController==None )
        GUIController = Class'KF2GUIController'.Static.GetGUIController(PlayerOwner);
    GUIController.CloseMenu(Page,bCloseAll);
}

reliable server function SetTurret( ST_Base T)
{
	TurretOwner = T;
	TurretOwner.CurrentUsers.AddItem(Self);
	//if(PlayerOwner==None)
	//	PlayerOwner = GetALocalPlayerController();
}

simulated function ExitedMenu()
{
	TurretOwner.CurrentUsers.RemoveItem(Self);
}

simulated function Destroyed()
{
	ClientCloseMenu( None, true );

	if( TurretOwner!=None )
		TurretOwner.CurrentUsers.RemoveItem(Self);
		super.Destroyed();
}

function bool CanAffordUpgrade(int Index)
{
	return PlayerOwner.PlayerReplicationInfo.Score >= TurretOwner.UpgradesObj.UpgradeInfos[Index].Cost;
}

reliable server function BuyUpgrade( int Index )
{
	if(PlayerOwner.PlayerReplicationInfo.Score >= TurretOwner.UpgradesObj.UpgradeInfos[Index].Cost)
	{
		TurretOwner.SentryWorth += TurretOwner.UpgradesObj.UpgradeInfos[Index].Cost;
		PlayerOwner.PlayerReplicationInfo.Score -= TurretOwner.UpgradesObj.UpgradeInfos[Index].Cost;
		TurretOwner.UpgradesObj.BoughtUpgrade(Index);
	}
}

reliable server function bool SellTurret()
{
	return TurretOwner.TryToSellTurret(PlayerOwner);
}

defaultproperties
{
   bOnlyRelevantToOwner=True
   bAlwaysRelevant=False
}
