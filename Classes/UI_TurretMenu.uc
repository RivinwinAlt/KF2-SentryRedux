Class UI_TurretMenu extends KFGUI_FloatingWindow;

struct FPageInfo
{
    var class<KFGUI_Base> PageClass;
    var string Caption,Hint;
};
var KFGUI_SwitchMenuBar PageSwitcher;
var() array<FPageInfo> Pages;

var KFGUI_Button SettingsButton,UpgradesButton;

var transient KFGUI_Button PrevButton;
var transient int NumButtons,NumButtonRows;
//var transient bool bInitSpectate,bOldSpectate;

var KFPlayerReplicationInfo KFPRI;

function InitMenu()
{
    local int i;
    local KFGUI_Button B;

    PageSwitcher = KFGUI_SwitchMenuBar(FindComponentID('Pager'));
    Super(KFGUI_Page).InitMenu();
    
    UpgradesButton = AddMenuButton('Upgrades',"Turret Upgrades","Show upgrades menu");
    SettingsButton = AddMenuButton('Settings',"Settings","Enter turret overlay settings");
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
    
}

function ShowMenu()
{
    local KFPlayerReplicationInfo PRI;
    
    Super.ShowMenu();

    PageSwitcher.SelectPage(0);
    
    PRI = KFPlayerReplicationInfo(GetPlayer().PlayerReplicationInfo);
    if( GetPlayer().WorldInfo.GRI!=None )
        WindowTitle = GetPlayer().WorldInfo.GRI.ServerName;
        
    UpgradesButton.SetDisabled( false );
    SettingsButton.SetDisabled( false );
        
    PlayMenuSound(MN_DropdownChange);
    
    // Update turret info.
    Timer();
    SetTimer(0.5,true);
}

function ButtonClicked( KFGUI_Button Sender )
{
    //local KFGUI_Page T;
    //local KFGameReplicationInfo KFGRI;
    //local KFPlayerReplicationInfo PRI;
    
    switch( Sender.ID )
    {
    case 'Settings':
        //Owner.OpenMenu(ClassicPlayerController(GetPlayer()).FlashUIClass);
        //KFPlayerController(GetPlayer()).MyGFxManager.OpenMenu(Sender.ID == 'Settings' ? UI_OptionsSelection : UI_Gear);
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
    WindowTitle="Killing Floor 2 - Sentry Turret Mod"
    XPosition=0.2
    YPosition=0.1
    XSize=0.6
    YSize=0.8
    
    bAlwaysTop=true
    bOnlyThisFocus=true
    
    Pages.Add((PageClass=Class'UIP_TurretUpgrades',Caption="Upgrades",Hint="Upgrade this turret"))
    Pages.Add((PageClass=Class'UIP_Settings',Caption="Settings",Hint="Show turret overlay settings"))

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