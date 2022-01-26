Class UIP_Settings extends KFGUI_MultiComponent;

var KFGUI_ComponentList SettingsBox;
var KFGUI_TextLable ResetColorLabel,PerkStarsLabel,PerkStarsRowLabel,ControllerTypeLabel,PlayerInfoTypeLabel;

var KFHUDInterface HUD;
var PlayerController PC;

function InitMenu()
{
    local string S;
    
    PC = PlayerController(GetPlayer());
    //HUD = KFHUDInterface(PC.myHUD);
    
    Super.InitMenu();

    // Client settings
    SettingsBox = KFGUI_ComponentList(FindComponentID('SettingsBox'));
    
    AddCheckBox("Light HUD","Show a light version of the HUD.",'bLight',HUD.bLightHUD);
    AddCheckBox("Show damage counter","Tally specimen damage on the HUD.",'bHideDamageMsg',!PC.bHideDamageMsg);
    
    AddButton("Reset","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors',ResetColorLabel);
}
final function KFGUI_CheckBox AddCheckBox( string Cap, string TT, name IDN, bool bDefault )
{
    local KFGUI_CheckBox CB;
    
    CB = KFGUI_CheckBox(SettingsBox.AddListComponent(class'KFGUI_CheckBox'));
    CB.LableString = Cap;
    CB.ToolTip = TT;
    CB.bChecked = bDefault;
    CB.InitMenu();
    CB.ID = IDN;
    CB.OnCheckChange = CheckChange;
    return CB;
}
final function KFGUI_Button AddButton( string ButtonText, string Cap, string TT, name IDN, out KFGUI_TextLable Label )
{
    local KFGUI_Button CB;
    local KFGUI_MultiComponent MC;
    
    MC = KFGUI_MultiComponent(SettingsBox.AddListComponent(class'KFGUI_MultiComponent'));
    MC.InitMenu();
    Label = new(MC) class'KFGUI_TextLable';
    Label.SetText(Cap);
    Label.XSize = 0.60;
    Label.FontScale = 1;
    Label.AlignY = 1;
    MC.AddComponent(Label);
    CB = new(MC) class'KFGUI_Button';
    CB.XPosition = 0.77;
    CB.XSize = 0.15;
    CB.ButtonText = ButtonText;
    CB.ToolTip = TT;
    CB.ID = IDN;
    CB.OnClickLeft = ButtonClicked;
    CB.OnClickRight = ButtonClicked;
    MC.AddComponent(CB);

    return CB;
}

function CheckChange( KFGUI_CheckBox Sender )
{
    local MusicGRI MGRI;
    local KFMapInfo KFMI;
    local KFGameReplicationInfo GRI;
    local KFPawn_Monster MPawn;
    local bool bHideKillMsg, bHideDamageMsg, bEnableDamagePopups, bHidePlayerDeathMsg;
    
    bHideKillMsg = PC.bHideKillMsg;
    bHideDamageMsg = PC.bHideDamageMsg;
    bHidePlayerDeathMsg = PC.bHidePlayerDeathMsg;
    bEnableDamagePopups = HUD.bEnableDamagePopups;

    switch( Sender.ID )
    {
    case 'bLight':
        HUD.bLightHUD = Sender.bChecked;
        break;
    case 'bWeapons':
        HUD.bHideWeaponInfo = !Sender.bChecked;
        break;
    case 'bPersonal':
        HUD.bHidePlayerInfo = !Sender.bChecked;
        break;
    case 'bScore':
        HUD.bHideDosh = !Sender.bChecked;
        break;
    }
    
    if( bHideKillMsg != PC.bHideKillMsg || bHideDamageMsg != PC.bHideDamageMsg || bEnableDamagePopups != HUD.bEnableDamagePopups || bHidePlayerDeathMsg != PC.bHidePlayerDeathMsg )
        PC.ServerSetSettings(PC.bHideKillMsg, PC.bHideDamageMsg, !HUD.bEnableDamagePopups, PC.bHidePlayerDeathMsg);
        
    HUD.SaveConfig();
    PC.SaveConfig();
}
function ButtonClicked( KFGUI_Button Sender )
{
    switch( Sender.ID )
    {
    case 'ResetColors':
        HUD.ResetHUDColors();
        if( PC.ColorSettingMenu != None )
        {
            PC.ColorSettingMenu.MainHudSlider.SetDefaultColor(HUD.HudMainColor);
            PC.ColorSettingMenu.OutlineSlider.SetDefaultColor(HUD.HudOutlineColor);
            PC.ColorSettingMenu.FontSlider.SetDefaultColor(HUD.FontColor);
        }
        break;
    }
}

defaultproperties
{
    Begin Object Class=KFGUI_ComponentList Name=ClientSettingsBox
        ID="SettingsBox"
        ListItemsPerPage=16
    End Object
    
    Components.Add(ClientSettingsBox)
}