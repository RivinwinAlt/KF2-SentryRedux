Class KFGUI_OverlayComponent extends Object
    abstract;

var ST_GUIController Owner;
var byte BackgroundOpacity; // Transperancy of the frame.
var bool bEnabled; // Don't draw the background.

var bool bWindowFocused; // This page is currently focused.

function DrawOverlay()
{
    if(BackgroundOpacity > 0)
    {
        //Owner.CurrentStyle.RenderOverlayBackground(Self);
    }
}

defaultproperties
{
    bEnabled = true
    BackgroundOpacity = 0
}