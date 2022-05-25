Class UIR_UpgradesList extends KFGUI_Frame;

var KFGUI_List UpgradeList;
var UI_PurchasePopup P;

var float ItemBorder, ItemPadding;
var float TextTopOffset;
var float ItemSpacing;
var float IconToInfoSpacing;

var Texture2D InfoBackground[3];

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
	local float TempX, TempY, GridX, GridY, CellW, CellH, GridH;
	local float IconSize;
	local float TempWidth, TempHeight;
	local float Sc;

	//convert index to reference an upgrade listed in dynamic array<int> AvailableUpgrades
	Index = UObj.AvailableUpgrades[Index];

	// Set up alignment grid
	GridX = Height;
	GridY = YOffset + ItemPadding;
	GridH = (Height - ItemPadding * 2.0f);
	CellW = (Width - GridX) / 2; // 2 Cells wide
	CellH = GridH / 2.0f; // 2 cells high

	TempX = 0.f; // Might need to make this =ItemPadding
	TempY = GridY;
	IconSize = GridH - (ItemBorder * 2.0f * GridH); // scale icon down within the list item

	// Initialize the Canvas
	C.Font = Owner.CurrentStyle.PickFont(Sc);

	// Draw Item Background
	C.SetDrawColor(255, 255, 255, 255);
	if(!CanAffordUpgrade(Index))
	{
		Owner.CurrentStyle.DrawTileStretched(InfoBackground[2], TempX, TempY, Width, GridH);
	}
	else if(bFocus)
	{
		Owner.CurrentStyle.DrawTileStretched(InfoBackground[1], TempX, TempY, Width, GridH);
	}
	else
	{
		Owner.CurrentStyle.DrawTileStretched(InfoBackground[0], TempX, TempY, Width, GridH);
	}

	// Offset and Calculate Icon's Size
	TempX += ItemBorder * GridH;
	TempY += ItemBorder * GridH;
	
	// Draw Icon
	C.DrawColor = UObj.UpgradeInfos[Index].DrawColor;
	Owner.CurrentStyle.DrawLibraryIcon(UObj.UpgradeInfos[Index].IconIndex, TempX, TempY, IconSize, IconSize);

	// Select Text Color
	C.SetDrawColor(236,227,203,255);

	// Draw the Upgrades Name
	C.TextSize(UObj.UpgradeInfos[Index].Title, TempWidth, TempHeight, Sc, Sc);
	TempX = GridX + ((CellW - TempWidth) / 2.0f); // Coord position 0,0 of the grid
	TempY = GridY + ((CellH - TempHeight) / 2.0f);
	C.SetPos(TempX, TempY);
	C.DrawText(UObj.UpgradeInfos[Index].Title,,Sc,Sc);

	// Draw the Upgrades Cost
	C.TextSize("$" $ UObj.UpgradeInfos[Index].Cost, TempWidth, TempHeight, Sc, Sc);
	TempX = GridX + ((CellW - TempWidth) / 2.0f); // Coord position 0,1 of the grid
	TempY = GridY + CellH + ((CellH - TempHeight) / 2.0f);
	C.SetPos(TempX, TempY);
	C.DrawText("$" $ UObj.UpgradeInfos[Index].Cost,,Sc,Sc);
	
	///Draw Desciption Text
	TempX = GridX + CellW + ItemBorder * GridH; // Coord position 1,0 of the grid
	TempY = GridY + ItemBorder * GridH;

	C.Font = Owner.CurrentStyle.PickFont(Sc, FONT_NUMBER); //FONT_NUMBER coresponds to int 1 as an enum
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
	
	InfoBackground[0] = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_NORMAL];
	InfoBackground[1] = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_HIGHLIGHTED];
	InfoBackground[2] = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_DISABLED];

	UpgradeList.OnDrawItem = DrawUpgradeInfo;
	UpgradeList.OnClickedItem = ClickedUpgrade;
	
	bTextureInit = true;
}

defaultproperties
{
	ItemPadding=7.0f // In pixels
	ItemBorder=0.11
	TextTopOffset=0.01
	ItemSpacing=0.0
	IconToInfoSpacing=0.05
	
	Begin Object Class=KFGUI_List Name=UpgradesList
		ID="Upgrades"
		ListItemsPerPage=7
		bClickable=true
		bHideScrollbar=false
		bUseFocusSound=true
	End Object

	Components.Add(UpgradesList)
}