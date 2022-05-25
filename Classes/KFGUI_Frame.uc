Class KFGUI_Frame extends KFGUI_FloatingWindow;
 
var() bool bDrawHeader, bHeaderCenter, bDrawBackground;
 
function InitMenu()
{
    Super(KFGUI_Page).InitMenu();
}

function DrawMenu()
{
    local float TempSize;
    
    if( bUseAnimation )
    {
        TempSize = `TimeSinceEx(GetPlayer(), OpenStartTime);
        if ( WindowFadeInTime - TempSize > 0 && FrameOpacity != default.FrameOpacity )
            FrameOpacity = (1.f - ((WindowFadeInTime - TempSize) / WindowFadeInTime)) * default.FrameOpacity;
    }
    
    if( bDrawBackground )
    {
        OnDrawFrame(Canvas, CompPos[2], CompPos[3]);
    }
}

delegate OnDrawFrame(Canvas C, float W, Float H)
{
    local float FontScale,XL,YL,HeaderH;
    local FontRenderInfo FRI;
    
    C.SetDrawColor(255,255,255,FrameOpacity);
    Owner.CurrentStyle.DrawTileStretched(Owner.CurrentStyle.BorderTextures[`BOX_INNERBORDER], 0, 0, W, H);
    
    if( bDrawHeader && WindowTitle!="" )
    {

        FRI.bClipText = true;
        FRI.bEnableShadow = true;
    
        C.Font = Owner.CurrentStyle.PickFont(FontScale, FONT_NAME);
        FontScale *= 0.8f;
        
        C.SetDrawColor(236,227,203,255);
        C.TextSize(WindowTitle, XL, YL, FontScale, FontScale);
        HeaderH = EdgeSizes[1] + EdgeSizes[2];
        
        C.SetPos((W - XL) / 2.0f, (HeaderH - YL) / 2.0f);
        C.DrawText(WindowTitle,,FontScale,FontScale,FRI);
    }
}
 
function PreDraw()
{
    local float Frac, CenterX, CenterY;
    
    if( !bVisible )
        return;
        
    if( bUseAnimation )
    {
        Frac = Owner.CurrentStyle.TimeFraction(OpenStartTime, OpenEndTime, GetPlayer().WorldInfo.RealTimeSeconds);
        XSize = Lerp(default.XSize*0.75, default.XSize, Frac);
        YSize = Lerp(default.YSize*0.75, default.YSize, Frac);
        
        CenterX = (default.XPosition + default.XSize * 0.5) - ((default.XSize*0.75)/2);
        CenterY = (default.YPosition + default.YSize * 0.5) - ((default.YSize*0.75)/2);
        
        XPosition = Lerp(CenterX, default.XPosition, Frac);
        YPosition = Lerp(CenterY, default.YPosition, Frac);
    }
 
    ComputeCoords();
    Canvas.SetDrawColor(255,255,255);
    Canvas.SetOrigin(CompPos[0], CompPos[1]);
    Canvas.SetClip(CompPos[0] + CompPos[2], CompPos[1] + CompPos[3]);
    DrawMenu();
    DrawComponents();
}

defaultproperties
{
    bUseAnimation=false
    bDrawHeader=true
    bDrawBackground=true
    
    FrameOpacity=255

    EdgeSizes(0)=20 // X-Border
    EdgeSizes(1)=20 // Y-Border
    EdgeSizes(2)=20 // Header Room
}