Class UIR_TurretInfoContainer extends KFGUI_Frame
    dependson(GUIStyleBase);

var KFGUI_List             InfoList;
var array<string>         InfoText;
//var ClassicPerk_Base     CurrentSelectedPerk;

var()    float            ItemBorder;
var()    float            ItemSpacing;
var()    float            TextTopOffset;

var    Texture                ItemBackground;

var string OwnerString, HealthString, ValueString;

var SentryUI_Network SN;

function InitMenu()
{
    InfoList = KFGUI_List(FindComponentID('Statistics'));
    SN = class'SentryUI_Network'.Static.GetNetwork(GetPlayer());

    Super.InitMenu();
}

function ShowMenu()
{
    Super.ShowMenu();
    
    SetTimer(0.2,true);
    Timer();
}

function DrawTurretInfo(Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus)
{
    local float AspectRatio;
    local float BorderSize;
    local float TempX, TempY, XL, YL;
    local float TempWidth, TempHeight;
    local float Sc;
    local string str;
    local int i;

    // Calculate the Aspect Ratio(Helps Widescreen)
    AspectRatio = Canvas.ClipX / Canvas.ClipY;

    // Calc BorderSize so we dont do it 10 times per draw
    BorderSize = (3.0 - AspectRatio) * ItemBorder * Width;

    // Offset for the Background
    TempX = 0.f;
    TempY = YOffset + ItemSpacing / 2.0;

    // Initialize the Canvas
    Canvas.Font = Owner.CurrentStyle.PickFont(Sc, FONT_NAME);
    Canvas.SetDrawColor(255, 255, 255, 255);

    // Draw Item Background
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawTileStretched(ItemBackground, Width, Height - ItemSpacing, 0, 0, ItemBackground.GetSurfaceWidth(), ItemBackground.GetSurfaceHeight());

    // Offset Border
    TempX += BorderSize;
    TempY += ((3.0 - AspectRatio) * BorderSize) + (TextTopOffset * Height);

    Canvas.SetDrawColor(240, 240, 240, 255);
    
    // Draw Header
    str = "Turret Information";
    Canvas.TextSize(str, XL, YL, Sc, Sc); //get text height for vertical line spacing
    Canvas.SetPos(TempX + ((Width - XL) / 2), TempY);
    Canvas.DrawText(str, , Sc, Sc);
    TempY += (YL * 1.75f);

    Canvas.Font = Owner.CurrentStyle.PickFont(Sc);

    // Draw Owner string
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawText(OwnerString, , Sc, Sc);
    TempY += YL;

    // Draw Health string
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawText(HealthString, , Sc, Sc);
    TempY += YL;

    // Draw Value string
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawText(ValueString, , Sc, Sc);
    //TempY += YL;
}

function Timer()
{
    //local UIP_PerkSelection SelectionParent;
    local array<string> ReqInfos;
    local int i;
    
    if( !bTextureInit )
    {
        GetStyleTextures();
    }

    if(SN != None)
    {
        OwnerString = "Owner: " $ SN.TurretOwner.GetOwnerName();
        HealthString = SN.TurretOwner.GetHealth() $ " ( " $ SN.TurretOwner.Health $ " / " $ SN.TurretOwner.HealthMax $ " )";
        ValueString = "Value: $" $ class'STHelper'.static.FormatNumber(SN.TurretOwner.SentryWorth);
    }
    
    /*SelectionParent = UIP_PerkSelection(ParentComponent);
    if( SelectionParent == None || CurrentSelectedPerk == SelectionParent.SelectedPerk )
        return;

    CurrentSelectedPerk = SelectionParent.SelectedPerk;
    
    for( i = 0; i < CurrentSelectedPerk.EXPActions.Length; i++ )
    {
        ReqInfos[i / 2] = ReqInfos[i / 2]$"|"$CurrentSelectedPerk.EXPActions[i];
    }
    
    RequirementsText = ReqInfos;
    RequirementList.ChangeListSize(ReqInfos.Length);
    */
}

function GatherTurretInfo()
{

}

function GetStyleTextures()
{
    if( !Owner.bFinishedReplication )
    {
        return;
    }
    
    ItemBackground = Owner.CurrentStyle.BorderTextures[`BOX_SMALL];
    
    InfoList.OnDrawItem = DrawTurretInfo;
    
    bTextureInit = true;
}

defaultproperties
{
    ItemBorder=0.018
    ItemSpacing=0.0
    TextTopOffset=-0.14
    
    Begin Object Class=KFGUI_List Name=TurretStats
        ID="Statistics"
        ListItemsPerPage=1
        bHideScrollbar=true
        bClickable=false
    End Object
    
    Components.Add(TurretStats)
}