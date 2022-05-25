Class UI_SentryMenu extends KFGUI_FloatingWindow;

struct FPageInfo
{
    var class<KFGUI_Base> PageClass;
    var string Caption,Hint;
};
var KFGUI_SwitchMenuBar PageSwitcher;
var() array<FPageInfo> Pages;

//var KFGUI_Button ;

var transient KFGUI_Button PrevButton;
var transient int NumButtons,NumButtonRows;

function InitMenu()
{
    local int i;
    local KFGUI_Button B;

    PageSwitcher = KFGUI_SwitchMenuBar(FindComponentID('Pager'));
    Super(KFGUI_Page).InitMenu();
    
    AddMenuButton('Sell',"Sell","Sell this turret");
    AddMenuButton('Close',"Close","Close this menu");
    
    for( i=0; i<Pages.Length; ++i )
    {
        PageSwitcher.AddPage(Pages[i].PageClass,Pages[i].Caption,Pages[i].Hint,B).InitMenu();
    }
}

function Timer()
{
    local PlayerReplicationInfo PRI;
    
    PRI = GetPlayer().PlayerReplicationInfo;
    if( PRI==None )
        return;
        
    if( KFPlayerController(GetPlayer()).IsBossCameraMode() )
    {
        DoClose();
        return;
    }
}

function ShowMenu()
{
    Super.ShowMenu();

    PageSwitcher.SelectPage(1);
    PlayMenuSound(MN_DropdownChange);
    
    // Update button text(depricated) Check for boss camera
    Timer();
    SetTimer(0.5,true);
}

function ButtonClicked( KFGUI_Button Sender )
{
    switch( Sender.ID )
    {
    case 'Sell':
        if(Owner.PlayerOwner == Owner.TurretOwner.OwnerController)
        {
            Owner.NetworkObj.SellTurret();
            DoClose();
        }
        break;
    case 'Close':
        DoClose();
        break;
    }
}

function DoClose()
{
    Owner.NetworkObj.ClosedMenu();
    super.DoClose();
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
    B.XPosition = 0.175 + NumButtons*0.5;
    B.XSize = 0.15;
    B.YPosition = 0.92;
    B.YSize = 0.08;

    ++NumButtons;
    
    AddComponent(B);
    return B;
}

defaultproperties
{
    WindowTitle="Sentry Redux Mod"
    XPosition=0
    YPosition=0
    XSize=0.6
    YSize=0.8
    
    bAlwaysTop=true
    bOnlyThisFocus=false
    bCenterCoords=true

    EdgeSizes(0)=20 // X-Border
    EdgeSizes(1)=20 // Y-Border
    EdgeSizes(2)=20 // Header Room
    
    Pages.Add((PageClass=Class'UIP_About',Caption="About",Hint="Mod info and credits"))
    Pages.Add((PageClass=Class'UIP_Upgrades',Caption="Upgrades",Hint="Purchase upgrades"))
    Pages.Add((PageClass=Class'UIP_Settings',Caption="Settings",Hint="Client mod settings"))
    Pages.Add((PageClass=Class'UIP_Debug',Caption="Debug",Hint="Debug Page for Creator"))

    Begin Object Class=KFGUI_SwitchMenuBar Name=MultiPager
        ID="Pager"
        XPosition=0
        YPosition=0
        XSize=1
        YSize=0.9
        BorderWidth=0.05
        ButtonAxisSize=0.1
    End Object
    
    Components.Add(MultiPager)
}