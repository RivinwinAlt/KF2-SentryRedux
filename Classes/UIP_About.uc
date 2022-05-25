Class UIP_About extends KFGUI_MultiComponent;

var UIR_CreditsContainer CreditsBox;

function InitMenu()
{
    CreditsBox = UIR_CreditsContainer(FindComponentID('CrditsBoxID'));

    Super.InitMenu();
}

defaultproperties
{
    Begin Object Class=UIR_CreditsContainer Name=CreditsField
        ID="CrditsBoxID"
        XPosition=0.0f
        YPosition=0.0f
        XSize=1.0f
        YSize=0.5f
        WindowTitle="Credits"
    End Object

    Components.Add(CreditsField)
}