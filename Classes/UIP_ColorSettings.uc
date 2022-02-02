Class UIP_ColorSettings extends KFGUI_MultiComponent;

var KFGUI_ComponentList SettingsBox;
var KFGUI_ColorSlider MainHudSlider,OutlineSlider,FontSlider;

function InitMenu()
{
    Super.InitMenu();

    // Client settings
    SettingsBox = KFGUI_ComponentList(FindComponentID('SettingsBox'));

    //MainHudSlider = AddColorSlider('HUDColorSlider', "Main HUD Color", KFHUDInterface(GetPlayer().myHUD).HudMainColor);
    //OutlineSlider = AddColorSlider('OutlineColorSlider', "HUD Outline Color", KFHUDInterface(GetPlayer().myHUD).HudOutlineColor);
    //FontSlider = AddColorSlider('FontCSlider', "Font Color", KFHUDInterface(GetPlayer().myHUD).FontColor);
}

function ShowMenu()
{
    Super.ShowMenu();
    //ClassicPlayerController(GetPlayer()).ColorSettingMenu = self;
}

final function KFGUI_ColorSlider AddColorSlider( name IDN, string Caption, Color DefaultColor )
{
    local KFGUI_MultiComponent MC;
    local KFGUI_ColorSlider SL;
    
    MC = KFGUI_MultiComponent(SettingsBox.AddListComponent(class'KFGUI_MultiComponent'));
    MC.XSize = 0.65;
    MC.XPosition = 0.15;
    MC.InitMenu();
    SL = new(MC) class'KFGUI_ColorSlider';
    SL.CaptionText = Caption;
    SL.DefaultColor = DefaultColor;
    SL.ID = IDN;
    SL.OnColorSliderValueChanged = CheckColorSliderChange;
    MC.AddComponent(SL);
    
    return SL;
}

function CheckColorSliderChange(KFGUI_ColorSlider Sender, KFGUI_Slider Slider, int Value)
{
}

function DrawMenu()
{
    Canvas.SetDrawColor(250,250,250,255);
    Canvas.SetPos(0.f,0.f);
    Canvas.DrawTileStretched(Owner.CurrentStyle.BorderTextures[`BOX_INNERBORDER],CompPos[2],CompPos[3],0,0,128,128);
}

defaultproperties
{
    Begin Object Class=KFGUI_ComponentList Name=ClientSettingsBox
        XPosition=0.05
        YPosition=0.05
        XSize=0.95
        YSize=0.95
        ID="SettingsBox"
        ListItemsPerPage=3
    End Object
    
    Components.Add(ClientSettingsBox)
}