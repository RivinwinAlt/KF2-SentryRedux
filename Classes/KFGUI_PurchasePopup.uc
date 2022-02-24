Class KFGUI_PurchasePopup extends KFGUI_FloatingWindow;

struct FPageInfo
{
    var class<KFGUI_Base> PageClass;
    var string Caption,Hint;
};

var transient int NumButtons;

var Color ButtonTextColor;
var SentryUI_Network SN;
var int UpgradeIndex;
var string UpgradeDescription;

function InitMenu()
{
    Super(KFGUI_Page).InitMenu();

    SN = class'SentryUI_Network'.Static.GetNetwork(GetPlayer());
    
    AddMenuButton('Cofirm',"Confirm","Finalize the purchase");
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
    
    Timer();
    SetTimer(0.5,true);
}

function DrawMenu()
{
    local float TempSize;
    
    if( bUseAnimation )
    {
        TempSize = `TimeSinceEx(GetPlayer(), OpenStartTime);
        if ( WindowFadeInTime - TempSize > 0 && FrameOpacity != default.FrameOpacity )
            FrameOpacity = (1.f - ((WindowFadeInTime - TempSize) / WindowFadeInTime)) * default.FrameOpacity;
    }
    
    Owner.CurrentStyle.RenderBuyConfirmation(Self);
    
    if( HeaderComp!=None )
    {
        HeaderComp.CompPos[3] = Owner.CurrentStyle.DefaultHeight;
        HeaderComp.YSize = HeaderComp.CompPos[3] / CompPos[3]; // Keep header height fit the window height.
    }
}

function ButtonClicked( KFGUI_Button Sender )
{
    switch( Sender.ID )
    {
    case 'Confirm':
        if(SN == None)
            SN = class'SentryUI_Network'.Static.GetNetwork(GetPlayer());
        SN.BuyUpgrade(UpgradeIndex);
        DoClose();
        break;
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
    B.TextColor = ButtonTextColor;
    B.ToolTip = ToolTipStr;
    B.OnClickLeft = ButtonClicked;
    B.OnClickRight = ButtonClicked;
    B.ID = ButtonID;
    B.XPosition = 0.05+NumButtons*0.5;
    B.XSize = 0.4;
    B.YPosition = 0.7;
    B.YSize = 0.25;

    NumButtons++;
    
    AddComponent(B);
    return B;
}

function SetUpgrade(int Index)
{
    UpgradeIndex = Index;
    UpgradeDescription = SN.TurretOwner.UpgradesObj.UpgradeInfos[Index].Description;
}

defaultproperties
{
    WindowTitle="Confirm Upgrade Purchase"
    XPosition=0.4
    YPosition=0.4
    XSize=0.2
    YSize=0.2

    ButtonTextColor=(R=240, G=240, B=240, A=255)
    
    bAlwaysTop=true
    bOnlyThisFocus=true
}