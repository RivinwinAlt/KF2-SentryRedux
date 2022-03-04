Class KFGUI_Frame extends KFGUI_FloatingWindow;
 
var() float EdgeSize[4]; // Pixels wide for edges (left, top, right, bottom).
var() float HeaderSize[2]; // Pixels wide for edges (left, top).
var() Texture FrameTex;
var() bool bDrawHeader,bHeaderCenter,bUseLegacyDrawTile,bDrawBackground;
 
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
    local int XS,YS;
    
    if( FrameTex == None )
    {
        return;
    }
    
    C.SetDrawColor(255,255,255,FrameOpacity);
    if( bUseLegacyDrawTile )
    {
        Owner.CurrentStyle.DrawTileStretched(FrameTex,0,0,W,H);
    }
    else 
    {
        Canvas.SetPos(0.f, 0.f);
        Canvas.DrawTileStretched(FrameTex,W,H,0,0,FrameTex.GetSurfaceWidth(),FrameTex.GetSurfaceHeight());
    }
   
    if( bDrawHeader && WindowTitle!="" )
    {
        XS = Canvas.ClipX-Canvas.OrgX;
        YS = Canvas.ClipY-Canvas.OrgY;

        FRI.bClipText = true;
        FRI.bEnableShadow = true;
    
        C.Font = Owner.CurrentStyle.PickFont(FontScale, FONT_NAME);
        FontScale *= 0.8f;
        
        C.SetDrawColor(240,240,240,FrameOpacity);
        C.TextSize(WindowTitle, XL, YL, FontScale, FontScale);
        HeaderH = EdgeSize[1]-HeaderSize[1];
        C.SetPos((W - XL) / 2.0f,(HeaderH - YL) / 2.0f);
        
        C.DrawText(WindowTitle,,FontScale,FontScale,FRI);
    }
}
 
function PreDraw()
{
    local int i;
    local byte j;
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
    Canvas.SetOrigin(CompPos[0],CompPos[1]);
    Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
    DrawMenu();
    
    for( i=0; i<Components.Length; ++i )
    {
        Components[i].Canvas = Canvas;
        for( j=0; j<4; ++j )
        {
            Components[i].InputPos[j] = CompPos[j]+EdgeSize[j];
        }
        Components[i].PreDraw();
    }
}

defaultproperties
{
    bUseAnimation=false
    bDrawHeader=true
    bUseLegacyDrawTile=true
    bDrawBackground=true
    
    FrameOpacity=255
    
    HeaderSize(0)=26.f
    HeaderSize(1)=8.f
   
    EdgeSize(0)=20
    EdgeSize(1)=35
    EdgeSize(2)=-40
    EdgeSize(3)=-50
}