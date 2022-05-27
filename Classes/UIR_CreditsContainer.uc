Class UIR_CreditsContainer extends KFGUI_Frame;

var KFGUI_TextField TF;

function InitMenu()
{
    TF = KFGUI_TextField(FindComponentID('AboutText'));
    Super.InitMenu();

    TF.SetText(BuildCreditsString());
}

function string BuildCreditsString()
{
    local string str;

    str = "Marco - Original creator of TF2 Sentry and Server Extension mods";
    str $= "|Commander Comrade Slav - Maintains TF2 Sentry mod workshop item";
    str $= "|Forrest Mark X - Provided customized menu code from KFClassicMode";
    str $= "|Rivinwin - Primary programmer, menu asset creation";
    str $= "|Rowdy Howdy - Creative coordinator and beta tester";
    str $= "|Dragontear - Custom wrench animations";
    str $= "|Jasper - Aided in extracting assets from TF2 and creating KF2 weapon assets";
//PyroHominid - menu icons
    return str;
}

defaultproperties
{
	Begin Object Class=KFGUI_TextField Name=AboutText
    ID="AboutText"
        XPosition=0.0
        YPosition=0.0
        XSize=1.0
        YSize=1.0
        Text="Credits from function"
    End Object
    
    Components.Add(AboutText)
}