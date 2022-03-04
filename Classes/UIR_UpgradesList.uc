Class UIR_UpgradesList extends KFGUI_Frame;

var KFGUI_List UpgradeList;
var UI_PurchasePopup P;

var float ItemBorder;
var float TextTopOffset;
var float ItemSpacing;
var float IconToInfoSpacing;

var string CostLabel;

var Texture PerkBackground;
var Texture InfoBackground;
var Texture SelectedPerkBackground;
var Texture SelectedInfoBackground;

var ST_Upgrades_Base UObj;

function InitMenu()
{
    UpgradeList = KFGUI_List(FindComponentID('Upgrades'));

    Super.InitMenu();
}

function ShowMenu()
{
    Super.ShowMenu();

    UObj = Owner.TurretOwner.UpgradesObj;
    UObj.LocalMenu = Self;
    UpdateListLength();

    SetTimer(0.5,true);
    Timer();
}

function UpdateListLength()
{
    UpgradeList.ChangeListSize(UObj.AvailableUpgrades.Length);
}

function bool CanAffordUpgrade(int Index)
{
    return Owner.PlayerOwner.PlayerReplicationInfo.Score >= UObj.UpgradeInfos[Index].Cost;
}

function DrawUpgradeInfo( Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus )
{
    local float TempX, TempY, HeldY1, HeldY2;
    local float IconSize;
    local float TempWidth, TempHeight;
    local float Sc;
    local Texture2D UpgradeIcon;

    //convert index to reference an upgrade listed in dynamic array<int> AvailableUpgrades
    Index = UObj.AvailableUpgrades[Index];

    TempX = 0.f;
    TempY = YOffset + ItemSpacing / 2.0f;
    IconSize = Height - ItemSpacing - (ItemBorder * 2.0 * Height);

    // Initialize the Canvas
    C.Font = Owner.CurrentStyle.PickFont(Sc);

    // Draw Item Background
    //C.SetPos(TempX, TempY);
    if(!CanAffordUpgrade(Index))
    {
        C.SetDrawColor(200,10,10, 255);

        //C.DrawTileStretched(PerkBackground, IconSize, IconSize, 0, 0, PerkBackground.GetSurfaceWidth(), PerkBackground.GetSurfaceHeight());
        //C.SetPos(TempX + IconSize - 1.0, YOffset + 7.0);
        C.SetPos(TempX, YOffset + 7.0);
        C.DrawTileStretched(InfoBackground, Width - IconSize, Height - ItemSpacing - 14, 0, 0, InfoBackground.GetSurfaceWidth(), InfoBackground.GetSurfaceHeight());
    }
    else if(bFocus)
    {
        C.SetDrawColor(255,255,255, 255);

        //C.DrawTileStretched(SelectedPerkBackground, IconSize, IconSize, 0, 0, SelectedPerkBackground.GetSurfaceWidth(), SelectedPerkBackground.GetSurfaceHeight());
        //C.SetPos(TempX + IconSize - 1.0, YOffset + 7.0);
        C.SetPos(TempX, YOffset + 7.0);
        C.DrawTileStretched(SelectedInfoBackground, Width, Height - ItemSpacing - 14, 0, 0, SelectedInfoBackground.GetSurfaceWidth(), SelectedInfoBackground.GetSurfaceHeight());
    }
    else
    {
        C.SetDrawColor(220,220,220, 255);

        //C.DrawTileStretched(PerkBackground, IconSize, IconSize, 0, 0, PerkBackground.GetSurfaceWidth(), PerkBackground.GetSurfaceHeight());
        //C.SetPos(TempX + IconSize - 1.0, YOffset + 7.0);
        C.SetPos(TempX, YOffset + 7.0);
        C.DrawTileStretched(InfoBackground, Width, Height - ItemSpacing - 14, 0, 0, InfoBackground.GetSurfaceWidth(), InfoBackground.GetSurfaceHeight());
    }

    // Offset and Calculate Icon's Size
    TempX += ItemBorder * Height;
    TempY += ItemBorder * Height;
    
    // Draw Icon
    C.DrawColor = UObj.UpgradeInfos[Index].DrawColor;
    C.SetPos(TempX, TempY);
    UpgradeIcon = UObj.UpgradeInfos[Index].Icon;
    C.DrawTileStretched(UpgradeIcon, IconSize, IconSize, 0, 0, UpgradeIcon.GetSurfaceWidth(), UpgradeIcon.GetSurfaceHeight());

    C.TextSize(UObj.UpgradeInfos[Index].Title, TempWidth, TempHeight, Sc, Sc);

    HeldY1 = TempY + (TextTopOffset * Height);
    TempX += IconSize + (IconToInfoSpacing * Width);
    HeldY2 = ((Height - ItemSpacing) / 3.0f);
    TempY = YOffset + HeldY2 + (ItemSpacing / 2.0f) - (TempHeight / 2.0f);

    // Select Text Color
    if ( bFocus )
        C.SetDrawColor(255, 255, 255, 255);
    else C.SetDrawColor(220, 220, 220, 255);

    // Draw the Upgrades Name
    //C.TextSize(SN.TurretOwner.UpgradesObj.UpgradeInfos[Index].Title, TempWidth, TempHeight, Sc, Sc);
    C.SetPos(TempX, TempY);
    C.DrawText(UObj.UpgradeInfos[Index].Title,,Sc,Sc);

    TempY += HeldY2;
    //TempY += TempHeight + (0.05 * Height);

    // Draw the Upgrades Cost
    C.TextSize(CostLabel $ UObj.UpgradeInfos[Index].Cost, TempWidth, TempHeight, Sc, Sc);
    C.SetPos(TempX, TempY);
    C.DrawText(CostLabel $ UObj.UpgradeInfos[Index].Cost,,Sc,Sc);
    
    ///Draw Desciption Text
    TempX = Width / 2.0f;
    TempY = HeldY1;

    C.Font = Owner.CurrentStyle.PickFont(Sc, FONT_NUMBER); //FONT_NUMBER corisponds to int 1 as an enum
    C.TextSize(UObj.UpgradeInfos[Index].Description, TempWidth, TempHeight, Sc, Sc);
    C.SetPos(TempX, TempY);
    C.DrawText(UObj.UpgradeInfos[Index].Description,,Sc,Sc);
}

function ClickedUpgrade( int Index, bool bRight, int MouseX, int MouseY )
{
    local int TIndex;
    TIndex = UObj.AvailableUpgrades[Index];
    if(Index >= 0 && CanAffordUpgrade(TIndex))
    {
        P = UI_PurchasePopup(Owner.OpenMenu(class'UI_PurchasePopup'));
        if(P != None)
            P.SetUpgrade(TIndex);
    }
}

function Timer()
{
    if( !bTextureInit )
    {
        GetStyleTextures();
    }
}

function GetStyleTextures()
{
    if( !Owner.bFinishedReplication )
    {
        return;
    }
    
    PerkBackground = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_NORMAL];
    InfoBackground = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_NORMAL];
    SelectedPerkBackground = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_NORMAL];
    SelectedInfoBackground = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_HIGHLIGHTED];
    
    UpgradeList.OnDrawItem = DrawUpgradeInfo;
    UpgradeList.OnClickedItem = ClickedUpgrade;
    
    bTextureInit = true;
}

defaultproperties
{
    ItemBorder=0.11
    TextTopOffset=0.01
    ItemSpacing=0.0
    IconToInfoSpacing=0.05
    CostLabel="Cost: $"
    
    Begin Object Class=KFGUI_List Name=UpgradesList
        ID="Upgrades"
        ListItemsPerPage=7
        bClickable=true
        bHideScrollbar=false
        bUseFocusSound=true
    End Object

    Components.Add(UpgradesList)
}