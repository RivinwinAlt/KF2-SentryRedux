Class UIP_Settings extends KFGUI_MultiComponent;

var UIR_SettingsContainer SettingsBox;

function InitMenu()
{
    SettingsBox = UIR_SettingsContainer(FindComponentID('SettingsBox'));

    Super.InitMenu();
}

defaultproperties
{
    Begin Object Class=UIR_SettingsContainer Name=ClientSettingsBox
        ID="SettingsBox"
        XPosition=0.0
        YPosition=0.0
        XSize=1.0
        YSize=1.0
        WindowTitle="Settings"
    End Object
    
    Components.Add(ClientSettingsBox)
}