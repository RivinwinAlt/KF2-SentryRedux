// Input while in a menu.
class KFGUI_Input extends KFPlayerInput;

var ST_GUIController ControllerOwner;
var PlayerInput BaseInput;

function PostRender( Canvas Canvas )
{
    if( ControllerOwner.bIsInMenuState )
    {
        ControllerOwner.RenderMenu(Canvas);
    }
    else
    {
        ControllerOwner.RenderOverlays(Canvas);
    }
}

// Postprocess the player's input
function PlayerInput( float DeltaTime )
{
    // Do not move.
    ControllerOwner.MenuInput(DeltaTime);
    
    if( !ControllerOwner.bAbsorbInput )
    {
        aMouseX = 0;
        aMouseY = 0;
        aBaseX = BaseInput.aBaseX;
        aBaseY = BaseInput.aBaseY;
        aBaseZ = BaseInput.aBaseZ;
        aForward = BaseInput.aForward;
        aTurn = BaseInput.aTurn;
        aStrafe = BaseInput.aStrafe;
        aUp = BaseInput.aUp;
        aLookUp = BaseInput.aLookUp;
        Super.PlayerInput(DeltaTime);
    }
    else
    {
        aMouseX = 0;
        aMouseY = 0;
        aBaseX = 0;
        aBaseY = 0;
        aBaseZ = 0;
        aForward = 0;
        aTurn = 0;
        aStrafe = 0;
        aUp = 0;
        aLookUp = 0;
    }
}

function PreClientTravel( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel)
{
    `Log("PreClientTravel"@PendingURL@TravelType@bIsSeamlessTravel);
    ControllerOwner.BackupInput.PreClientTravel(PendingURL,TravelType,bIsSeamlessTravel); // Let original mod do stuff too!
    ControllerOwner.NotifyLevelChange(); // Close menu NOW!
}

defaultproperties
{
}