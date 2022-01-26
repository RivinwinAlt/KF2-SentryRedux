Class UI_MidGameMenu extends KFGUI_FloatingWindow;

struct FPageInfo
{
    var class<KFGUI_Base> PageClass;
    var string Caption,Hint;
};
var KFGUI_SwitchMenuBar PageSwitcher;
var() array<FPageInfo> Pages;

var KFGUI_Button ExitMenuBtn, SellTurretBtn;

var transient KFGUI_Button PrevButton;
var transient int NumButtons,NumButtonRows;

var KFPlayerReplicationInfo KFPRI;

function InitMenu()
{
    local int i;
    local KFGUI_Button B;

    PageSwitcher = KFGUI_SwitchMenuBar(FindComponentID('Pager'));
    Super(KFGUI_Page).InitMenu();
    
    SellTurretBtn = AddMenuButton('Sell',"Sell Turret","Sell to Recieve Partial Refund");
    ExitMenuBtn = AddMenuButton('Close',"Close","Close this menu");
    
    for( i=0; i < Pages.Length; ++i )
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
        
    if( KFPlayerController(GetPlayer()).IsBossCameraMode() ) // what is isbosscameramode?
    {
        DoClose();
        return;
    }
}

function ShowMenu()
{
    local KFPlayerReplicationInfo PRI;
    
    Super.ShowMenu();

    PageSwitcher.SelectPage(0);
    
    PRI = KFPlayerReplicationInfo(GetPlayer().PlayerReplicationInfo);
    if( GetPlayer().WorldInfo.GRI!=None )
        WindowTitle = GetPlayer().WorldInfo.GRI.ServerName;

    PlayMenuSound(MN_DropdownChange);
}

function ButtonClicked( KFGUI_Button Sender )
{
    local KFGUI_Page T;
    local KFGameReplicationInfo KFGRI;
    local KFPlayerReplicationInfo PRI;
    
    switch( Sender.ID )
    {
    case 'Sell':
        break;
    case 'Close':
        break;
    }
    
    DoClose();
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
    B.XPosition = 0.05+NumButtons*0.1;
    B.XSize = 0.099;
    B.YPosition = 0.92+NumButtonRows*0.04;
    B.YSize = 0.0399;

    PrevButton = B;
    if( ++NumButtons>8 )
    {
        ++NumButtonRows;
        NumButtons = 0;
    }
    
    AddComponent(B);
    return B;
}

defaultproperties
{
    WindowTitle="Killing Floor 2 - Classic Mode"
    XPosition=0.2
    YPosition=0.1
    XSize=0.6
    YSize=0.8
    
    bAlwaysTop=true
    bOnlyThisFocus=true
    
    
    Pages.Add((PageClass=Class'UIP_TurretMenu',Caption="Upgrades",Hint="Spend that money"))
    Pages.Add((PageClass=Class'UIP_Settings',Caption="Settings",Hint="Show mod settings"))
    Pages.Add((PageClass=Class'UIP_About',Caption="About",Hint="Updates and credits"))

    Begin Object Class=KFGUI_SwitchMenuBar Name=MultiPager
        ID="Pager"
        XPosition=0.015
        YPosition=0.04
        XSize=0.975
        YSize=0.8
        BorderWidth=0.05
        ButtonAxisSize=0.1
    End Object
    
    Components.Add(MultiPager)
}