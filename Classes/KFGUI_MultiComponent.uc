Class KFGUI_MultiComponent extends KFGUI_Base;

var() export editinline array<KFGUI_Base> Components;
var() float EdgeSizes[3]; // Pixels wide for edges (left/right, top/bottom, extra top)

function InitMenu()
{
    local int i;
    
    for( i=0; i<Components.Length; ++i )
    {
        Components[i].Owner = Owner;
        Components[i].ParentComponent = Self;
        Components[i].InitMenu();
    }
}
function ShowMenu()
{
    local int i;
    
    for( i=0; i<Components.Length; ++i )
        Components[i].ShowMenu();
}
function PreDraw()
{
    if( !bVisible )
        return;

    ComputeCoords();
    Canvas.SetDrawColor(255,255,255);
    Canvas.SetOrigin(CompPos[0],CompPos[1]);
    Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
    DrawMenu();
    DrawComponents();
}

function DrawComponents()
{
    local int i;

    for( i=0; i<Components.Length; ++i )
    {
        Components[i].Canvas = Canvas;
        Components[i].InputPos[0] = CompPos[0] + EdgeSizes[0];
        Components[i].InputPos[1] = CompPos[1] + EdgeSizes[1] + EdgeSizes[2];
        Components[i].InputPos[2] = CompPos[2] - (EdgeSizes[0] * 2.0f);
        Components[i].InputPos[3] = CompPos[3] - (EdgeSizes[1] * 2.0f) - EdgeSizes[2];
        
        Components[i].PreDraw();
    }
}

function InventoryChanged(optional KFWeapon Wep, optional bool bRemove)
{
    local int i;
    
    for( i=0; i<Components.Length; ++i )
        Components[i].InventoryChanged(Wep,bRemove);
}
function MenuTick( float DeltaTime )
{
    local int i;

    Super.MenuTick(DeltaTime);
    for( i=0; i<Components.Length; ++i )
        Components[i].MenuTick(DeltaTime);
}

function AddComponent( KFGUI_Base C, optional int X = 0, optional int Y = 0, optional int W = 1, optional int H = 1 )
{
    Components[Components.Length] = C;
    C.Owner = Owner;
    C.ParentComponent = Self;
    C.InitMenu();
}

function CloseMenu()
{
    local int i;
    
    for( i=0; i<Components.Length; ++i )
        Components[i].CloseMenu();
}
function bool CaptureMouse()
{
    local int i;
    
    for( i=Components.Length - 1; i>=0; i-- )
    {
        if( Components[i].CaptureMouse() )
        {
            MouseArea = Components[i];
            return true;
        }
    }
    MouseArea = None;
    return Super.CaptureMouse(); // check with frame itself.
}
function bool ReceievedControllerInput(int ControllerId, name Key, EInputEvent Event)
{
    local int i;
    
    for( i=Components.Length - 1; i>=0; i-- )
    {
        if( Components[i].ReceievedControllerInput(ControllerId, Key, Event) )
        {
            return true;
        }
    }
    
    return Super.ReceievedControllerInput(ControllerId, Key, Event);
}
function KFGUI_Base FindComponentID( name InID )
{
    local int i;
    local KFGUI_Base Result;

    if( ID==InID )
        Result = Self;
    else
    {
        for( i=0; i<Components.Length && Result==None; ++i )
            Result = Components[i].FindComponentID(InID);
    }
    return Result;
}
function FindAllComponentID( name InID, out array<KFGUI_Base> Res )
{
    local int i;

    if( ID==InID )
        Res[Res.Length] = Self;
    for( i=0; i<Components.Length; ++i )
        Components[i].FindAllComponentID(InID,Res);
}
function RemoveComponent( KFGUI_Base B )
{
    local int i;
    
    for( i=0; i<Components.Length; ++i )
        if( Components[i]==B )
        {
            Components.Remove(i,1);
            B.CloseMenu();
            return;
        }
    for( i=0; i<Components.Length; ++i )
        Components[i].RemoveComponent(B);
}
function NotifyLevelChange()
{
    local int i;
    
    for( i=0; i<Components.Length; ++i )
        Components[i].NotifyLevelChange();
}

DefaultProperties
{
    EdgeSizes(0)=0 // X-Border
    EdgeSizes(1)=0 // Y-Border
    EdgeSizes(2)=0 // Header Room
}