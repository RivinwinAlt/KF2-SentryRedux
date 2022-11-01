// Each Player Actor actually has their own object of this type on both the server and client as a simulated proxy.
class ST_SentryNetwork extends ReplicationInfo
	dependson(ST_Upgrades_Base); // Gives access to upgrade enums;

var ST_Turret_Base TurretOwner;
var repnotify PlayerController PlayerOwner;

var transient ST_Settings_Rep Settings;
var transient byte SendIndex;
var transient ST_GUIController GUIController;
var transient bool bActiveTimer;

replication
{
	if( bNetDirty )
		PlayerOwner;
}

simulated event ReplicatedEvent( name VarName )
{
	if(VarName == 'PlayerOwner')
	{
		SetOwner(PlayerOwner); // Enables function replication to owner
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
	{
		if(SN != none)
		{
			`log("ST_SentryNetwork: Returning reference to existing object");
			return SN;
		}
	}

	`log("ST_SentryNetwork: Creating new object");
	SN = PC.Spawn(class'ST_SentryNetwork', PC);
	SN.PlayerOwner = PC;
	
	return SN;
}

function UpdateTurretMessage(optional bool Enabled = true)
{
	local KFInterface_Usable UsableActor;

	if(!Enabled)
	{
		ClearTimer(nameof(CheckTurretUsableActor));
		PlayerOwner.ReceiveLocalizedMessage(class'ST_InteractMessage', STI_None);
		return;
	}

	if(PlayerOwner != none)
	{
		UsableActor = KFPlayerController(PlayerOwner).GetCurrentUsableActor(PlayerOwner.Pawn);
		if(ST_Trigger_Base(UsableActor) != none)
		{
			SetTimer(1.f, true, nameof(CheckTurretUsableActor));
			PlayerOwner.ReceiveLocalizedMessage(class'ST_InteractMessage', STI_UseTurret, none, none, UsableActor);
		}
		else
		{
			ClearTimer(nameof(CheckTurretUsableActor));
			PlayerOwner.ReceiveLocalizedMessage(class'ST_InteractMessage', STI_None);
		}
	}
}

function CheckTurretUsableActor()
{
	local KFInterface_Usable UsableActor;

	UsableActor = KFPlayerController(PlayerOwner).GetCurrentUsableActor(PlayerOwner.Pawn);
	if(ST_Trigger_Base(UsableActor) != none)
	{
		PlayerOwner.ReceiveLocalizedMessage(class'ST_InteractMessage', STI_UseTurret);
	}
	else
	{
		ClearTimer(nameof(CheckTurretUsableActor));
		PlayerOwner.ReceiveLocalizedMessage( class'ST_InteractMessage', STI_None );
	}
}

simulated reliable client function ClientOpenMenu(ST_Turret_Base NewTurret)
{
	if(WorldInfo.NetMode != NM_Client)
		return;
	TurretOwner = NewTurret;
	if( GUIController==None )
		GUIController = Class'ST_GUIController'.Static.GetGUIController(PlayerOwner);
	GUIController.TurretOwner = NewTurret;
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
	PlayerOwner.PlayerReplicationInfo.Score -= TurretOwner.UpgradesObj.UpgradeInfos[Index].Costs[TurretOwner.UpgradesObj.PurchasedUpgrades[Index - 1]];
	TurretOwner.UpgradesObj.BoughtUpgrade(Index);
}

reliable server function PerformAmmoPurchase(int Index, int Amount)
{
	PlayerOwner.PlayerReplicationInfo.Score -= TurretOwner.AddAmmo(Index, Amount) * TurretOwner.UpgradesObj.AmmoInfos[Index].CostPerRound;
}

reliable server function SellTurret()
{
	TurretOwner.TryToSellTurret(PlayerOwner);
}

reliable server function TakeTurret()
{
	if(TurretOwner.OwnerController == none)
		TurretOwner.SetTurretOwner(PlayerOwner);
}

reliable server function Orphan()
{
	TurretOwner.SetTurretOwner(None);
}

reliable server function ClosedMenu()
{
	GUIController = none;
	UpdateTurretMessage();
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
