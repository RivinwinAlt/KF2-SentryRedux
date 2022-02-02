Class UIP_Settings extends KFGUI_MultiComponent;

var KFGUI_ComponentList SettingsBox;
var KFGUI_TextLable ResetColorLabel,PerkStarsLabel,PerkStarsRowLabel,ControllerTypeLabel,PlayerInfoTypeLabel;
var KFGUI_EditBox PerkStarsBox, PerkRowsBox;
var KFGUI_ComboBox ControllerBox;

//var KFHUDInterface HUD;
var KFGFxHudWrapper HUD;
var PlayerController PC;

function InitMenu()
{
    //local string S;
    
    PC = GetPlayer();
    
    Super.InitMenu();

    // Client settings
    SettingsBox = KFGUI_ComponentList(FindComponentID('SettingsBox'));
    
    /*
    ControllerBox = AddComboBox("Player Info Type","What style to draw the player info system in.",'PlayerInfo',PlayerInfoTypeLabel);
    ControllerBox.Values.AddItem("Classic");
    ControllerBox.Values.AddItem("Legacy");
    ControllerBox.Values.AddItem("Modern");
    ControllerBox.SetValue(S);
    */
    
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
final function KFGUI_EditBox AddEditBox( string Cap, string TT, name IDN, string DefaultValue, out KFGUI_TextLable Label )
{
    local KFGUI_EditBox EB;
    local KFGUI_MultiComponent MC;
    
    MC = KFGUI_MultiComponent(SettingsBox.AddListComponent(class'KFGUI_MultiComponent'));
    MC.InitMenu();
    Label = new(MC) class'KFGUI_TextLable';
    Label.SetText(Cap);
    Label.XSize = 0.60;
    Label.FontScale = 1;
    Label.AlignY = 1;
    MC.AddComponent(Label);
    EB = new(MC) class'KFGUI_EditBox';
    EB.XPosition = 0.77;
    EB.YPosition = 0.5;
    EB.XSize = 0.15;
    EB.YSize = 1;
    EB.ToolTip = TT;
    EB.bDrawBackground = true;
    EB.ID = IDN;
    EB.OnChange = OnTextChanged;
    EB.SetText(DefaultValue);
    EB.bNoClearOnEnter = true;
    MC.AddComponent(EB);

    return EB;
}
final function KFGUI_ComboBox AddComboBox( string Cap, string TT, name IDN, out KFGUI_TextLable Label )
{
    local KFGUI_ComboBox CB;
    local KFGUI_MultiComponent MC;
    
    MC = KFGUI_MultiComponent(SettingsBox.AddListComponent(class'KFGUI_MultiComponent'));
    MC.InitMenu();
    Label = new(MC) class'KFGUI_TextLable';
    Label.SetText(Cap);
    Label.XSize = 0.60;
    Label.FontScale = 1;
    Label.AlignY = 1;
    MC.AddComponent(Label);
    CB = new(MC) class'KFGUI_ComboBox';
    CB.XPosition = 0.77;
    CB.XSize = 0.15;
    CB.ToolTip = TT;
    CB.ID = IDN;
    CB.OnComboChanged = OnComboChanged;
    MC.AddComponent(CB);

    return CB;
}

function OnComboChanged(KFGUI_ComboBox Sender)
{
    switch( Sender.ID )
    {
    case 'ControllerType':
        break;
    }
}

function OnTextChanged(KFGUI_EditBox Sender)
{
    switch( Sender.ID )
    {
    case 'MaxPerkStars':
        break;
    }
}

function CheckChange( KFGUI_CheckBox Sender )
{
    //local MusicGRI MGRI;
    //local KFMapInfo KFMI;
    //local KFGameReplicationInfo GRI;
    //local KFPawn_Monster MPawn;
    //local bool bHideKillMsg, bHideDamageMsg, bEnableDamagePopups, bHidePlayerDeathMsg;
    

    switch( Sender.ID )
    {
    case 'bLight':
        //HUD.bLightHUD = Sender.bChecked;
        break;
    }
}
function ButtonClicked( KFGUI_Button Sender )
{
    switch( Sender.ID )
    {
    case 'ResetColors':
        
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