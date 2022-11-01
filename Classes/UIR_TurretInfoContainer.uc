Class UIR_TurretInfoContainer extends KFGUI_Frame;

var KFGUI_TextField InfoList;

var() float ItemBorder;
var() float ItemSpacing;
var() float TextTopOffset;

var string OwnerString, HealthString, ValueString;
var Texture2D ItemBackground;
var float UpdatePeriod;

var ST_Upgrades_Base UObj;

function InitMenu()
{
	InfoList = KFGUI_TextField(FindComponentID('Statistics'));

	Super.InitMenu();
}

function ShowMenu()
{
	UObj = Owner.TurretOwner.UpgradesObj;
    SetTimer(UpdatePeriod, true, 'RefreshStats');
    RefreshStats();
    
    Super.ShowMenu();
}

function RefreshStats()
{
	if(InfoList != none )
	{
		if(Owner.TurretOwner != None)
		{
			OwnerString = "Owner: " $ Owner.TurretOwner.GetOwnerName();
			HealthString = "HP: " $ Owner.TurretOwner.GetHealth() $ " ( " $ Owner.TurretOwner.Health $ " / " $ Owner.TurretOwner.HealthMax $ " )";
			ValueString = "Value: $" $ class'ST_StaticHelper'.static.FormatNumber(Owner.TurretOwner.DoshValue);
			
			InfoList.SetText(OwnerString $ "|" $ HealthString $ "|" $ ValueString);
		}
		else
		{
			InfoList.SetText("No Turret Assigned");
		}
	}
}

function DoClose()
{
	ClearTimer('RefreshStats');
	super.DoClose();
}

defaultproperties
{
	UpdatePeriod=0.5f

	ItemBorder=0.018
	ItemSpacing=0.0
	TextTopOffset=-0.14
	
	Begin Object Class=KFGUI_TextField Name=TurretStats
		ID="Statistics"
		XPosition=0
        YPosition=0
        XSize=1
        YSize=1
		Text="Not Initialized"
		bClickable=false
	End Object
	
	Components.Add(TurretStats)
}