Class KFGUI_Button extends KFGUI_Clickable;

var() Canvas.CanvasIcon OverlayTexture;
var() string ButtonText,GamepadButtonName;
var() color TextColor;
var() Canvas.FontRenderInfo TextFontInfo;
var() byte FontScale,ExtravDir;
var bool bIsHighlighted;

function DrawMenu()
{
    if(!bDisabled)
        Owner.CurrentStyle.RenderButton(Self);
}

function bool GetUsingGamepad()
{
    return Owner.bUsingGamepad && GamepadButtonName != "";
}

function HandleMouseClick( bool bRight )
{
    if(!bEnabled)
        return;
    if( bRight )
        OnClickRight(Self);
    else OnClickLeft(Self);
}

Delegate OnClickLeft( KFGUI_Button Sender );
Delegate OnClickRight( KFGUI_Button Sender );

Delegate bool DrawOverride(Canvas C, KFGUI_Button B)
{
    return false;
}

defaultproperties
{
    ButtonText="Button!"
    TextColor=(R=236,G=227,B=203,A=255) // From TF2 menu text
    TextFontInfo=(bClipText=true,bEnableShadow=true)
    FontScale=1
}