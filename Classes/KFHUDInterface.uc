class KFHUDInterface extends KFHUDBase
    config(ClassicHUD);

const HUDBorderSize = 3;

const PHASE_DONE = -1;
const PHASE_SHOWING = 0;
const PHASE_DELAYING = 1;
const PHASE_HIDING = 2;

enum EJustificationType
{
    HUDA_None,
    HUDA_Right,
    HUDA_Left,
    HUDA_Top,
    HUDA_Bottom
};

enum PopupPosition 
{
    PP_BOTTOM_CENTER,
    PP_BOTTOM_LEFT,
    PP_BOTTOM_RIGHT,
    PP_TOP_CENTER,
    PP_TOP_LEFT,
    PP_TOP_RIGHT
};

enum EPriorityAlignment
{
    PR_TOP,
    PR_BOTTOM
};

enum EPriorityAnimStyle
{
    ANIM_SLIDE,
    ANIM_DROP
};

struct FNewItemEntry
{
    var Texture2D Icon;
    var string Item,IconURL;
    var float MsgTime;
};
var transient array<FNewItemEntry> NewItems;
var transient array<byte> WasNewlyAdded;
var transient OnlineSubsystem OnlineSub;
var transient bool bLoadedInitItems;

var transient vector PLCameraLoc,PLCameraDir;
var transient rotator PLCameraRot;

var float TimeX;

var transient bool bInterpolating, bNeedsRepLinkUpdate, bObjectReplicationFinished, bReplicatedColorTextures;
var Color DefaultHudMainColor, DefaultHudOutlineColor, DefaultFontColor;

var float BorderSize;

var int MaxNonCriticalMessages;
var float NonCriticalMessageDisplayTime,NonCriticalMessageFadeInTime,NonCriticalMessageFadeOutTime;

struct FCritialMessage
{
    var string Text, Delimiter;
    var float StartTime;
    var bool bHighlight,bUseAnimation;
    var int TextAnimAlpha;
};
var transient array<FCritialMessage> NonCriticalMessages;

struct FPriorityMessage
{
    var string PrimaryText, SecondaryText;
    var float StartTime, SecondaryStartTime, LifeTime, FadeInTime, FadeOutTime;
    var EPriorityAlignment SecondaryAlign;
    var EPriorityAnimStyle PrimaryAnim, SecondaryAnim;
    var Texture2D Icon,SecondaryIcon;
    var Color IconColor,SecondaryIconColor;
    var bool bSecondaryUsesFullLength;
    
    structdefaultproperties
    {
        FadeInTime=0.15f
        FadeOutTime=0.15f
        LifeTime=5.f
        IconColor=(R=255,G=255,B=255,A=255)
        SecondaryIconColor=(R=255,G=255,B=255,A=255)
    }
};
var transient FPriorityMessage PriorityMessage;
var int CurrentPriorityMessageA,CurrentSecondaryMessageA;

struct HUDBoxRenderInfo
{
    var int JustificationPadding;
    var Color TextColor, OutlineColor, BoxColor;
    var Texture IconTex;
    var float Alpha;
    var float IconScale;
    var array<String> StringArray;
    var bool bUseOutline, bUseRounded, bRoundedOutline, bHighlighted;
    var EJustificationType Justification;
    
    structdefaultproperties
    {
        TextColor=(R=255,B=255,G=255,A=255)
        Alpha=-1.f
        IconScale=1.f
    }
};

var const Color BlueColor;

struct PopupMessage 
{
    var string Header;
    var string Body;
    var Texture2D Image;
    var PopupPosition MsgPosition;
};
var privatewrite int NotificationPhase;
var privatewrite array<PopupMessage> MessageQueue;
var privatewrite string NewLineSeparator;
var float NotificationWidth, NotificationHeight, NotificationPhaseStartTime, NotificationIconSpacing, NotificationShowTime, NotificationHideTime, NotificationHideDelay, NotificationBorderSize;
var Texture NotificationBackground;

var float ScaledBorderSize;

var transient KF2GUIController GUIController;
var transient GUIStyleBase GUIStyle;

var transient KF2GUIInput CustomInput;
var transient PlayerInput BackupInput;
var transient GameViewportClient ClientViewport;

var transient bool bIsMenu;

simulated function PostBeginPlay()
{    
    Super.PostBeginPlay();
    
    PlayerOwner.PlayerInput.OnReceivedNativeInputKey = NotifyInputKey;
    PlayerOwner.PlayerInput.OnReceivedNativeInputAxis = NotifyInputAxis;
    PlayerOwner.PlayerInput.OnReceivedNativeInputChar = NotifyInputChar;
}

function PostRender()
{    
    if( GUIController!=None && PlayerOwner.PlayerInput==None )
        GUIController.NotifyLevelChange();
        
    if( GUIController==None || GUIController.bIsInvalid )
    {
        GUIController = Class'KF2GUIController'.Static.GetGUIController(PlayerOwner);
        if( GUIController!=None )
        {
            GUIStyle = GUIController.CurrentStyle;
        }
    }
    GUIStyle.Canvas = Canvas;
    GUIStyle.PickDefaultFontSize(Canvas.ClipY);
    
    ScaledBorderSize = FMax(GUIStyle.ScreenScale(HUDBorderSize), 1.f);
    
    Super.PostRender();
    
    PlayerOwner.GetPlayerViewPoint(PLCameraLoc,PLCameraRot);
    PLCameraDir = vector(PLCameraRot);
}

delegate DrawAdditionalInfo(Canvas C, float Y);

function color GetMsgColor( bool bDamage, int Count )
{
    local float T;

    if( bDamage )
    {
        if( Count>1500 )
            return MakeColor(148,0,0,255);
        else if( Count>1000 )
        {
            T = (Count-1000) / 500.f;
            return MakeColor(148,0,0,255)*T + MakeColor(255,0,0,255)*(1.f-T);
        }
        else if( Count>500 )
        {
            T = (Count-500) / 500.f;
            return MakeColor(255,0,0,255)*T + MakeColor(255,255,0,255)*(1.f-T);
        }
        T = Count / 500.f;
        return MakeColor(255,255,0,255)*T + MakeColor(0,255,0,255)*(1.f-T);
    }
    if( Count>20 )
        return MakeColor(255,0,0,255);
    else if( Count>10 )
    {
        T = (Count-10) / 10.f;
        return MakeColor(148,0,0,255)*T + MakeColor(255,0,0,255)*(1.f-T);
    }
    else if( Count>5 )
    {
        T = (Count-5) / 5.f;
        return MakeColor(255,0,0,255)*T + MakeColor(255,255,0,255)*(1.f-T);
    }
    T = Count / 5.f;
    return MakeColor(255,255,0,255)*T + MakeColor(0,255,0,255)*(1.f-T);
}

static function string StripMsgColors( string S )
{
    local int i;
    
    while( true )
    {
        i = InStr(S,Chr(6));
        if( i==-1 )
            break;
        S = Left(S,i)$Mid(S,i+2);
    }
    return S;
}

static function string GetNameArticle( string S )
{
    switch( Caps(Left(S,1)) ) // Check if a vowel, then an.
    {
    case "A":
    case "E":
    case "I":
    case "O":
    case "U":
        return "an";
    }
    return "a";
}

static function string GetNameOf( class<Pawn> Other )
{
    local string S;
    local class<KFPawn_Monster> KFM;
        
    KFM = class<KFPawn_Monster>(Other);
    if( KFM!=None )
        return KFM.static.GetLocalizedName();
        
    if( Other.Default.MenuName!="" )
        return Other.Default.MenuName;
        
    S = string(Other.Name);
    if( Left(S,10)~="KFPawn_Zed" )
        S = Mid(S,10);
    else if( Left(S,7)~="KFPawn_" )
        S = Mid(S,7);
    S = Repl(S,"_"," ");
    
    return S;
}

final function vector FindEdgeIntersection( float XDir, float YDir, float ClampSize )
{
    local vector V;
    local float TimeXS,TimeYS,SX,SY;

    // First check for paralell lines.
    if( Abs(XDir)<0.001f )
    {
        V.X = Canvas.ClipX*0.5f;
        if( YDir>0.f )
            V.Y = Canvas.ClipY-ClampSize;
        else V.Y = ClampSize;
    }
    else if( Abs(YDir)<0.001f )
    {
        V.Y = Canvas.ClipY*0.5f;
        if( XDir>0.f )
            V.X = Canvas.ClipX-ClampSize;
        else V.X = ClampSize;
    }
    else
    {
        SX = Canvas.ClipX*0.5f;
        SY = Canvas.ClipY*0.5f;

        // Look for best intersection axis.
        TimeXS = Abs((SX-ClampSize) / XDir);
        TimeYS = Abs((SY-ClampSize) / YDir);
        
        if( TimeXS<TimeYS ) // X axis intersects first.
        {
            V.X = TimeXS*XDir;
            V.Y = TimeXS*YDir;
        }
        else
        {
            V.X = TimeYS*XDir;
            V.Y = TimeYS*YDir;
        }
        
        // Transform axis to screen center.
        V.X += SX;
        V.Y += SY;
    }
    return V;
}

/*
function DrawMessageText(HudLocalizedMessage LocalMessage, float ScreenX, float ScreenY)
{
    local class<ClassicLocalMessage> ClassicMessage;
    
    ClassicMessage = class<ClassicLocalMessage>(LocalMessage.Message);
    if( ClassicMessage != None && ClassicMessage.default.bComplexString )
        ClassicMessage.static.RenderComplexMessage(Canvas, ScreenX, ScreenY, LocalMessage.StringMessage, LocalMessage.Switch, LocalMessage.OptionalObject);
    else Super.DrawMessageText(LocalMessage, ScreenX, ScreenY);
}
*/

//TODO: Update Font assets here
static function Font GetFontSizeIndex(int FontSize)
{
    switch(FontSize)
    {
        case 0:
            return Font'EngineFonts.TinyFont';
        case 1:
            return Font'UI_Canvas_Fonts.Font_Main';
        default:
            return Font'UI_Canvas_Fonts.Font_Main';
    }
}

function bool NotifyInputKey(int ControllerId, Name Key, EInputEvent Event, float AmountDepressed, bool bGamepad)
{
    local int i;
    /*
    for( i=(HUDWidgets.Length-1); i>=0; --i )
    {
        if( HUDWidgets[i].bVisible && HUDWidgets[i].NotifyInputKey(ControllerId, Key, Event, AmountDepressed, bGamepad) )
            return true;
    }
    */
    return false;
}

function bool NotifyInputAxis(int ControllerId, name Key, float Delta, float DeltaTime, optional bool bGamepad)
{
    local int i;
    /*
    for( i=(HUDWidgets.Length-1); i>=0; --i )
    {
        if( HUDWidgets[i].bVisible && HUDWidgets[i].NotifyInputAxis(ControllerId, Key, Delta, DeltaTime, bGamepad) )
            return true;
    }
    */
    return false;
}

function bool NotifyInputChar(int ControllerId, string Unicode)
{
    local int i;
    /*
    for( i=(HUDWidgets.Length-1); i>=0; --i )
    {
        if( HUDWidgets[i].bVisible && HUDWidgets[i].NotifyInputChar(ControllerId, Unicode) )
            return true;
    }
    */
    return false;
}

simulated function Destroyed()
{
    Super.Destroyed();
    NotifyLevelChange();
    ResetConsole();
}

function ResetConsole()
{
    /*
    if( OrgConsole == None || ClientViewport.ViewportConsole == OrgConsole )
        return;
        
    ClientViewport.ViewportConsole = OrgConsole;
    OrgConsole.OnReceivedNativeInputKey = OrgConsole.InputKey;
    OrgConsole.OnReceivedNativeInputChar = OrgConsole.InputChar;
    */
}

simulated function NotifyLevelChange( optional bool bMapswitch )
{
}

defaultproperties
{
    MaxNonCriticalMessages=2
    
    DefaultHudMainColor=(R=0,B=0,G=0,A=195)
    DefaultHudOutlineColor=(R=200,B=15,G=15,A=195)
    DefaultFontColor=(R=255,B=50,G=50,A=255)
    
    BlueColor=(R=0,B=255,G=0,A=255)

    BorderSize=0.005

    NonCriticalMessageDisplayTime=3.0
    NonCriticalMessageFadeInTime=0.65
    NonCriticalMessageFadeOutTime=0.5
    
    NewLineSeparator="|"
    
    NotificationBackground=Texture2D'tf2sentry.HUD.Med_border_SlightTransparent'
    NotificationWidth=250.0f
    NotificationHeight=70.f
    NotificationShowTime=0.3
    NotificationHideTime=0.5
    NotificationHideDelay=3.5
    NotificationBorderSize=7.0
    NotificationIconSpacing=10.0
    NotificationPhase=PHASE_DONE
}