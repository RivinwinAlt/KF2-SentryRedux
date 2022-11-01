Class UI_PurchasePopup extends KFGUI_FloatingWindow;

struct FPageInfo
{
	var class<KFGUI_Base> PageClass;
	var string Caption,Hint;
};

var transient int NumButtons;

var int UpgradeIndex;
var string UpgradeDescription;
var UIR_PurchaseDesc DescriptionBox;

var ST_Upgrades_Base UObj;

function InitMenu()
{
	Super(KFGUI_Page).InitMenu();

	DescriptionBox = UIR_PurchaseDesc(FindComponentID('DescriptionField'));
	
	AddMenuButton('Confirm',"Confirm","Finalize the purchase");
	AddMenuButton('Cancel',"Cancel","Cancel purchase");
}

function Timer()
{
	if( KFPlayerController(GetPlayer()).IsBossCameraMode() )
	{
		DoClose();
		return;
	}
}

function ShowMenu()
{
	Super.ShowMenu();
	
	PlayMenuSound(MN_DropdownChange);
}

function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'Confirm':
		// Use Networking Object to call server function
		Owner.NetworkObj.PerformPurchase(UpgradeIndex);
	case 'Cancel':
		DoClose();
		break;
	}
}

final function KFGUI_Button AddMenuButton( name ButtonID, string Text, optional string ToolTipStr )
{
	local KFGUI_Button B;
	
	B = new (Self) class'KFGUI_Button';
	B.ButtonText = Text;
	B.ToolTip = ToolTipStr;
	B.OnClickLeft = ButtonClicked;
	B.OnClickRight = ButtonClicked;
	B.ID = ButtonID;
	B.XPosition = NumButtons*0.6;
	B.XSize = 0.4;
	B.YPosition = 0.8;
	B.YSize = 0.2;

	NumButtons++;
	
	AddComponent(B);
	return B;
}

function SetUpgrade(int Index)
{
	UObj = Owner.TurretOwner.UpgradesObj;
	UpgradeIndex = Index;
	DescriptionBox.TF.SetText(UObj.UpgradeInfos[Index].Description);
}

defaultproperties
{
	WindowTitle="Confirm Upgrade Purchase"
	XPosition=0
	YPosition=0
	XSize=0.3
	YSize=0.3
	
	bAlwaysTop=true
	bOnlyThisFocus=true
	bCenterCoords=true

	EdgeSizes(0)=20 // X-Border
    EdgeSizes(1)=20 // Y-Border
    EdgeSizes(2)=20 // Header Room

	Begin Object Class=UIR_PurchaseDesc Name=DescField
        ID="DescriptionField"
        XPosition=0.0
        YPosition=0.0
        XSize=1.0
        YSize=0.75
        WindowTitle=""
    End Object

    Components.Add(DescField)
}