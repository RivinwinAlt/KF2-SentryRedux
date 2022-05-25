Class UIR_PurchaseDesc extends KFGUI_Frame;

var KFGUI_TextField TF;

function InitMenu()
{
    TF = KFGUI_TextField(FindComponentID('DescriptionText'));
    Super.InitMenu();
}

defaultproperties
{
	Begin Object Class=KFGUI_TextField Name=UpgText
    ID="DescriptionText"
        XPosition=0.0
        YPosition=0.0
        XSize=1.0
        YSize=1.0
        FontScale=0.8
        Text="Upgrade Description Here"
    End Object
    Components.Add(UpgText)

    EdgeSizes(0)=15 // X-Border
    EdgeSizes(1)=15 // Y-Border
    EdgeSizes(2)=0 // Header Room
}