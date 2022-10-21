// Extending off KFGUI_Base now instead of KFGUI_ComponentList as it implements the same functionality as KFGUI_MultiComponent but in a different way

class KFGUI_CategoryList extends KFGUI_Base;

var array<KFGUI_Category> Categories;
var KFGUI_ScrollBarV ScrollBar;
var class<KFGUI_CategoryButton> CatButtonClass;
var array<KFGUI_Base> RenderedComponents;

var int ListCount;
var float RowPadding, ColumnPadding;

var() int ListItemsPerPage;
var() bool bDrawBackground, bHideScrollbar, bUseFocusSound;

function InitMenu()
{
	Super.InitMenu();
	//ScrollBar = KFGUI_ScrollBarV(FindComponentID('Scrollbar'));
	ScrollBar.bHideScrollbar = bHideScrollbar;
	ScrollBar.Owner = Owner;
	ScrollBar.ParentComponent = Self;
	ScrollBar.OnScrollChange = TriggerArrayRebuild;
	ScrollBar.InitMenu();
}

function KFGUI_Category AddCategory(name CatID, string CatTitle, optional int NumCol = 1, optional bool PreExpanded = false)
{
	local KFGUI_Category NewCat;

	NewCat = new(Self) class'KFGUI_Category';
	NewCat.HeaderComponent = new(Self) CatButtonClass;
	NewCat.CategoryTitle = CatTitle;
	NewCat.Owner = Owner;
	NewCat.ParentComponent = Self;
	NewCat.NumColumns = NumCol;
	NewCat.CategoryID = CatID;
	NewCat.bExpanded = PreExpanded;
	NewCat.InitMenu();

	Categories.AddItem(NewCat);

	return NewCat;
}

function KFGUI_Base AddItemToCategory(name CatID, class<KFGUI_Base> ItemClass, optional float XS=1.f, optional float YS=1.f)
{
	local int i;
	local bool found;
	local KFGUI_Base NewComp;

	// Search for the specified KFGUI_Category
	for(i = 0; i < Categories.Length; i++)
	{
		if(Categories[i].CategoryID == CatID)
		{
			found = true;
			break;
		}
	}
	// If KFGUI_Category doesn't exist create it
	if(!found)
	{
		i = Categories.Length;
		AddCategory(CatID, string(CatID)); // Use CatID as the category name
	}

	// At this point i is the index of Categories that corresponds to the CatID specified
	NewComp = Categories[i].AddComponent(ItemClass);
	NewComp.XPosition = (1.0 - XS) / 2.0f; // Automatically center the component inside its render area
	NewComp.YPosition = (1.0 - YS) / 2.0f;
	NewComp.XSize = XS;
	NewComp.YSize = YS;
	
	return NewComp;
}

// Counts up the total number of visible items into ListCount if LengthChangeFlags are set
function UpdateListLength(optional bool ForceCalc = false)
{
	local KFGUI_Category TempCat;
	local bool DoCalc;

	// Check for changes to length
	foreach Categories(TempCat)
	{
		if(TempCat.LengthChangeFlag)
			DoCalc = true;
	}
	if(!DoCalc && !ForceCalc)
		return;
	
	// Count the list length and reset Category.LengthChangeFlags
	ListCount = Categories.Length;
	foreach Categories(TempCat)
	{
		ListCount += TempCat.GetLength();
	}

	UpdateScrollBar(); // Loops arround through delegate and calls TriggerArrayRebuild()
}

final function TriggerArrayRebuild(KFGUI_ScrollBarBase Sender, int Value)
{
	RenderedComponents.Length = 0;
}

function UpdateScrollBar()
{
	if( ListCount<=ListItemsPerPage )
	{
		ScrollBar.UpdateScrollSize(0,1,1,1);
		ScrollBar.SetDisabled(true);
	}
	else
	{
		ScrollBar.UpdateScrollSize(ScrollBar.CurrentScroll,(ListCount-ListItemsPerPage),1,ListItemsPerPage);
		ScrollBar.SetDisabled(false);
	}
}

function ScrollMouseWheel( bool bUp )
{
	ScrollBar.ScrollMouseWheel(bUp);
}

function RemoveCategory(name CatID)
{
	local int i;
	
	i = EmptyList(CatID);
	if(i != -1)
	{
		Categories.Remove(i, 1);
		RenderedComponents.Length = 0;
		UpdateListLength(true);
	}
}

// Returns the KFGUI_Category's array index
function int EmptyList(name CatID)
{
	local int i;
	
	for(i = 0; i < Categories.length; i++)
	{
		if(Categories[i].CategoryID == CatID)
		{
			Categories[i].Components.length = 0;
			return i;
		}
	}
	
	return -1; // Returns a value of -1 if the KFGUI_Category could not be found
}

function PreDraw()
{
	local byte j;
	
	if( !bVisible )
		return;

	ComputeCoords();
	UpdateListLength();
	
	// If enabled draw ScrollBar and shrink to accomodate
	if( !ScrollBar.bDisabled && !ScrollBar.bHideScrollbar )
	{
		for( j=0; j<4; ++j )
			ScrollBar.InputPos[j] = CompPos[j];
		ScrollBar.Canvas = Canvas;
		ScrollBar.PreDraw();
		
		// Then downscale our selves to give room for scrollbar.
		CompPos[2] -= ScrollBar.CompPos[2] * 1.5f;
	}
	
	Canvas.SetOrigin(CompPos[0],CompPos[1]);
	Canvas.SetPos(0, 0);
	Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
	DrawMenu();
	PreDrawListItems();
}

function DrawMenu()
{
	if( bDrawBackground )
	{
		Canvas.SetDrawColor(255,255,255,255);
		Owner.CurrentStyle.DrawTileStretched(Owner.CurrentStyle.BorderTextures[`BOX_INNERBORDER], 0, 0, CompPos[2], CompPos[3]);
	}
}

function PreDrawListItems()
{
	local int i, StartIndex, RenderLimit, Row, Col, NumSeparators;
	local float XS, YS, SeparatorStartY, SeparatorHeight;
	local KFGUI_Category TempCat;
	local bool bBuildArray;

	// Check if we need to populate the array used for mouse capturing
	// Trigger rebuild elsewhere by emptying the array (RenderedComponents.Length = 0;)
	if(RenderedComponents.Length == 0)
		bBuildArray = true;

	SeparatorHeight = 0.0f;
	NumSeparators = 0;
	SeparatorStartY = -1.0f;
	StartIndex = ScrollBar.CurrentScroll;
	RenderLimit = ListItemsPerPage;
	YS = CompPos[3] / ListItemsPerPage;
	Row = 0;

	foreach Categories(TempCat)
	{
		if(RenderLimit <= 0)
			return;

		if(StartIndex > 0)
			--StartIndex;
		else
		{
			Canvas.SetOrigin(CompPos[0],CompPos[1]);
			Canvas.SetPos(0, 0);
			Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
			TempCat.HeaderComponent.Canvas = Canvas;
			TempCat.HeaderComponent.InputPos[0] = CompPos[0];
			TempCat.HeaderComponent.InputPos[1] = CompPos[1] + (YS * Row) + (RowPadding / 2.0f);
			TempCat.HeaderComponent.InputPos[2] = CompPos[2];
			TempCat.HeaderComponent.InputPos[3] = YS - RowPadding;
			TempCat.HeaderComponent.PreDraw();
			if(bBuildArray)
				RenderedComponents.AddItem(TempCat.HeaderComponent);
			--RenderLimit;
			Row++;
		}

		if(TempCat.bExpanded)
		{
			XS = CompPos[2] / TempCat.NumColumns;
			Col = 0;
			RenderLimit *= TempCat.NumColumns; // Allow for multiple components only taking up one row

			for(i = 0; i < TempCat.Components.Length; ++i)
			{
				if(RenderLimit <= 0)
				{
					// Draw separators if were exiting mid-list with columns
					if(SeparatorStartY > -0.5f)
					{
						DrawSeparators(SeparatorStartY, SeparatorHeight, NumSeparators);
					}
					return;
				}

				if(StartIndex > 0) // Don't render component
				{
					--StartIndex;
					i += TempCat.NumColumns - 1; // Skips rendering the rest of the row
				}
				else
				{
					// Set up component
					TempCat.Components[i].Canvas = Canvas;
					TempCat.Components[i].InputPos[0] = CompPos[0] + (XS * Col) + (ColumnPadding / 2.0f);
					TempCat.Components[i].InputPos[1] = CompPos[1] + (YS * Row) + (RowPadding / 2.0f);
					TempCat.Components[i].InputPos[2] = XS - ColumnPadding;
					TempCat.Components[i].InputPos[3] = YS - RowPadding;

					// Check if we're starting a set of columns
					if(SeparatorStartY == -1 && TempCat.NumColumns > 1)
					{
						// Initialize separator drawing info
						NumSeparators = TempCat.NumColumns; // Have to record this for use outside the current loop
						SeparatorStartY = (YS * Row) + (RowPadding / 2.0f);
						SeparatorHeight = 0;
					}

					// Render component
					Canvas.SetOrigin(CompPos[0],CompPos[1]);
					Canvas.SetPos(0, 0);
					Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
					TempCat.Components[i].PreDraw();
					if(bBuildArray)
						RenderedComponents.AddItem(TempCat.Components[i]);
					--RenderLimit;
					++Col;
					if(Col >= TempCat.NumColumns)
					{
						Col = 0;
						++Row;
						if(SeparatorStartY != -1)
						SeparatorHeight += YS;
					}
				}
			}

			// Account for partial rows with more than 1 column
			if(Col > 0)
			{
				SeparatorHeight += YS;
				++Row;
			}

			// Check if we need to draw separators
			if(SeparatorStartY > -0.5f)
			{
				DrawSeparators(SeparatorStartY, SeparatorHeight, NumSeparators);
				SeparatorStartY = -1; // Turn separator drawing back off till we encounter a new set
			}

			RenderLimit /= TempCat.NumColumns; // Automatically rounds down using integer division
		}
	}
}

function DrawSeparators(float PosY, float YS, int NumColumns)
{
	local int i;
	local float TexW, ColW;

	TexW = Owner.CurrentStyle.ColumnSeparator.GetSurfaceWidth();
	ColW = CompPos[2] / NumColumns;

	for(i = 1; i < NumColumns; ++i)
	{
		Canvas.SetOrigin(CompPos[0],CompPos[1]);
		Canvas.SetPos(0, 0);
		Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
		Owner.CurrentStyle.DrawTileStretched(Owner.CurrentStyle.ColumnSeparator, (ColW * i) - (TexW / 2.0f), PosY, TexW, YS);
	}
}

function bool CaptureMouse()
{
	local KFGUI_Base TempComp;

	foreach RenderedComponents(TempComp)
	{
		if(TempComp.CaptureMouse())
		{
			MouseArea = TempComp;
			return true;
		}
	}

	if(ScrollBar.CaptureMouse())
		MouseArea = ScrollBar;
	
	return false;
}

// Call CloseMenu for every component
function CloseMenu()
{
	local int i, j;

	for(i = 0; i < Categories.Length; ++i)
	{
		Categories[i].HeaderComponent.CloseMenu();
		for(j = 0; j < Categories[i].Components.Length; ++j)
		{
			Categories[i].Components[j].CloseMenu();
		}
	}
	Super.CloseMenu();
}

function NotifyLevelChange()
{
    local int i, j;

	for(i = 0; i < Categories.Length; ++i)
	{
		Categories[i].HeaderComponent.NotifyLevelChange();
		for(j = 0; j < Categories[j].Components.Length; ++j)
		{
			Categories[i].Components[j].NotifyLevelChange();
		}
	}
	Super.NotifyLevelChange();
}

// Call InventoryChanged for every component
function InventoryChanged(optional KFWeapon Wep, optional bool bRemove)
{
	local int i, j;

	for(i = 0; i < Categories.Length; ++i)
	{
		Categories[i].HeaderComponent.InventoryChanged(Wep,bRemove);
		for(j = 0; j < Categories[j].Components.Length; ++j)
		{
			Categories[i].Components[j].InventoryChanged(Wep,bRemove);
		}
	}
}

function MenuTick( float DeltaTime )
{
    local int i, j;

    Super.MenuTick(DeltaTime);
	for(i = 0; i < Categories.Length; ++i)
	{
		Categories[i].HeaderComponent.MenuTick(DeltaTime);
		for(j = 0; j < Categories[i].Components.Length; ++j)
		{
			Categories[i].Components[j].MenuTick(DeltaTime);
		}
	}
}

defaultproperties
{
	ColumnPadding=16 // Space between columns, does not effect Separator texture draw width
	RowPadding = 5.0f
	ListItemsPerPage = 10
	//BackgroundColor=(R=0,G=0,B=0,A=75)
	bClickable=true
	bDrawBackground=false
	bUseFocusSound=false
	bHideScrollbar=false

	CatButtonClass = class'KFGUI_CategoryButton'

	Begin Object Class=KFGUI_ScrollBarV Name=ListScroller
		XPosition=0
		YPosition=0
		XSize=1.0
		YSize=1.0
		ID="Scrollbar"
	End Object
	ScrollBar=ListScroller
}