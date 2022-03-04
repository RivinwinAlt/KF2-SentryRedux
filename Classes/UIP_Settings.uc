Class UIP_Settings extends KFGUI_MultiComponent;

var KFGUI_ComponentList SettingsBox;

function InitMenu()
{
    Super.InitMenu();

    // Client settings
    SettingsBox = KFGUI_ComponentList(FindComponentID('SettingsBox'));
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
}

function CheckChange( KFGUI_CheckBox Sender )
{
}

function ButtonClicked( KFGUI_Button Sender )
{
    /*
    switch( Sender.ID )
    {
    case 'ResetColors':
        break;
    }
    */
}

defaultproperties
{
    Begin Object Class=KFGUI_ComponentList Name=ClientSettingsBox
        ID="SettingsBox"
        ListItemsPerPage=16
    End Object
    
    Components.Add(ClientSettingsBox)
}