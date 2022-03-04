Class UIR_AmmoListContainer extends KFGUI_Frame;

var KFGUI_List AmmoList;
var byte CurrentPerkLevel;
var Color ButtonTextColor;
var KFGUI_Button BuyButtons[6];
var int BuyAmount[6];

var float ItemBorder;

var Texture AmmoBackground;

function InitMenu()
{
	AmmoList = KFGUI_List(FindComponentID('AmmoL'));
	Super.InitMenu();
}

function ShowMenu()
{
	Super.ShowMenu();

	AmmoList.ChangeListSize(3);
	
	SetTimer(0.2, true);
	Timer();
}

function bool AmmoTypeEnabled(int Index)
{
	return Owner.TurretOwner.MaxAmmoCount[Index] > 0;
}

function bool HasAmmo(int Index)
{
	return Owner.TurretOwner.AmmoCount[Index] > 0;
}

function DrawAmmoInfo( Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus )
{
	local float TempX, TempY, GridX, GridY, CellW, CellH;
	local float IconSize;
	local float TempWidth, TempHeight;
	local float Sc;
	local string TempStr;
	local Texture2D AmmoIcon;

	// Dont render for disabled ammo types
	if(!AmmoTypeEnabled(Index))
		return;

	GridX = Height;
	GridY = YOffset + 7.0f;
	CellW = (Width - GridX) / 4; // 4 Cells wide
	CellH = (Height - 14.0f) / 2; // 2 cells high

	TempX = 0.f;
	TempY = GridY;
	IconSize = Height - (ItemBorder * 2.0 * Height);

	// Initialize the Canvas
	C.Font = Owner.CurrentStyle.PickFont(Sc);

	// Draw Item Background
	//C.SetPos(TempX, TempY);
	if(!HasAmmo(Index))
	{
		C.SetDrawColor(200,10,10, 255);
		C.SetPos(TempX, YOffset + 7.0f);
		C.DrawTileStretched(AmmoBackground, Width, Height - 14.0f, 0, 0, AmmoBackground.GetSurfaceWidth(), AmmoBackground.GetSurfaceHeight());
	}
	else
	{
		C.SetDrawColor(220,220,220, 255);
		C.SetPos(TempX, YOffset + 7.0f);
		C.DrawTileStretched(AmmoBackground, Width, Height - 14.0f, 0, 0, AmmoBackground.GetSurfaceWidth(), AmmoBackground.GetSurfaceHeight());
	}

	// Offset and Calculate Icon's Size
	TempX += ItemBorder * Height;
	TempY += ItemBorder * Height;

	// Draw Icon
	C.DrawColor = Owner.TurretOwner.UpgradesObj.AmmoInfos[Index].DrawColor;
	C.SetPos(TempX, TempY);
	AmmoIcon = Owner.TurretOwner.UpgradesObj.AmmoInfos[Index].Icon;
	C.DrawTileStretched(AmmoIcon, IconSize, IconSize, 0, 0, AmmoIcon.GetSurfaceWidth(), AmmoIcon.GetSurfaceHeight());

	// Select Text Color
	C.SetDrawColor(220, 220, 220, 255);

	// Draw the Current Ammo and Max
	C.TextSize(Owner.TurretOwner.AmmoCount[Index] $ " / " $ Owner.TurretOwner.MaxAmmoCount[Index], TempWidth, TempHeight, Sc, Sc);
	TempX = GridX + (CellW - (TempWidth / 2.0f)); // Coord position 0,0 of the grid
	TempY = GridY + (CellH - (TempHeight / 2.0f));
	C.SetPos(TempX, TempY);
	C.DrawText(Owner.TurretOwner.AmmoCount[Index] $ " / " $ Owner.TurretOwner.MaxAmmoCount[Index],,Sc,Sc);

	// Draw cost for partial ammo
	TempStr = "$" $ BuyAmount[Index * 2] * Owner.TurretOwner.UpgradesObj.AmmoInfos[Index].CostPerRound;
	C.TextSize(TempStr, TempWidth, TempHeight, Sc, Sc);
	TempX = GridX + (CellW * 2) + ((CellW - TempWidth) / 2); // Coord position 2,1 of the grid
	TempY = GridY + CellH + ((CellH - TempHeight) / 2);
	C.SetPos(TempX, TempY);
	C.DrawText(TempStr,,Sc,Sc);
	
	// Draw cost to fill ammo
	TempStr = "$" $ BuyAmount[(Index * 2) + 1] * Owner.TurretOwner.UpgradesObj.AmmoInfos[Index].CostPerRound;
	C.TextSize(TempStr, TempWidth, TempHeight, Sc, Sc);
	TempX = GridX + (CellW * 3) + ((CellW - TempWidth) / 2); // Coord position 3,1 of the grid
	TempY = GridY + CellH + ((CellH - TempHeight) / 2);
	C.SetPos(TempX, TempY);
	C.DrawText(TempStr,,Sc,Sc);

	// Buttons
	if(BuyButtons[Index * 2] == none)
	{
		TempX = (GridX + (CellW * 2)) / AmmoList.CompPos[2];
		TempY = GridY / AmmoList.CompPos[3];
		BuyButtons[Index * 2] = AddButton(Index * 2, TempX, TempY, CellW / AmmoList.CompPos[2], CellH / AmmoList.CompPos[3]); // X Y W H
		TempX = (GridX + (CellW * 3)) / AmmoList.CompPos[2];
		BuyButtons[(Index * 2) + 1] = AddButton((Index * 2) + 1, TempX, TempY, CellW / AmmoList.CompPos[2], CellH / AmmoList.CompPos[3]); // X Y W H
	}
}

function Timer()
{
	local int i, v;

	if( !bTextureInit )
	{
		GetStyleTextures();
	}

	for(i = 0; i < 3; i++)
	{
		if(AmmoTypeEnabled(i) && BuyButtons[i * 2] != none)
		{
			v = Owner.TurretOwner.MaxAmmoCount[i] - Owner.TurretOwner.AmmoCount[i];
			BuyAmount[i * 2] = Min(v, Owner.TurretOwner.UpgradesObj.AmmoInfos[i].BuyAmount);
			BuyAmount[(i * 2) + 1] = v;
			BuyButtons[i * 2].bEnabled = true;
			BuyButtons[i * 2].ButtonText = "Buy " $ BuyAmount[i * 2];
			BuyButtons[(i * 2) + 1].bEnabled = true;
		}
		else if(BuyButtons[i * 2] != none)
		{
			BuyButtons[i * 2].bEnabled = false;
			BuyButtons[(i * 2) + 1].bEnabled = false;
		}
	}
}

function GetStyleTextures()
{
	if( !Owner.bFinishedReplication )
	{
		return;
	}
	
	AmmoBackground = Owner.CurrentStyle.ItemBoxTextures[`ITEMBOX_NORMAL];
	
	AmmoList.OnDrawItem = DrawAmmoInfo;
	
	bTextureInit = true;
}

function ButtonClicked( KFGUI_Button Sender )
{
	// Perform local check before sending buy-request through network object
	switch( Sender.ID )
	{
	case 'Primary':
		if(CanAffordAmmo(0, BuyAmount[0]))
			Owner.NetworkObj.PerformAmmoPurchase(0, BuyAmount[0]);
		break;
	case 'PrimaryFill':
		if(CanAffordAmmo(0, BuyAmount[1]))
			Owner.NetworkObj.PerformAmmoPurchase(0, BuyAmount[1]);
		break;
	case 'Secondary':
		if(CanAffordAmmo(1, BuyAmount[2]))
			Owner.NetworkObj.PerformAmmoPurchase(1, BuyAmount[2]);
		break;
	case 'SecondaryFill':
		if(CanAffordAmmo(1, BuyAmount[3]))
			Owner.NetworkObj.PerformAmmoPurchase(1, BuyAmount[3]);
		break;
	case 'Special':
		if(CanAffordAmmo(2, BuyAmount[4]))
			Owner.NetworkObj.PerformAmmoPurchase(2, BuyAmount[4]);
		break;
	case 'SpecialFill':
		if(CanAffordAmmo(2, BuyAmount[5]))
			Owner.NetworkObj.PerformAmmoPurchase(2, BuyAmount[5]);
		break;
	}
}

function bool CanAffordAmmo(int Index, int Amount)
{
	return Owner.PlayerOwner.PlayerReplicationInfo.Score >= Amount * Owner.TurretOwner.UpgradesObj.AmmoInfos[Index].CostPerRound;
}

final function KFGUI_Button AddButton(int ButtonIndex, float X, float Y, float W, float H)
{
	local KFGUI_Button B;
	local string ToolTipStr;

	if(ButtonIndex > 5)
		return none;

	B = new (Self) class'KFGUI_Button';

	switch(ButtonIndex)
	{
	case 0:
		B.ID = 'Primary';
		B.ButtonText = "Buy ";
		break;
	case 1:
		B.ID = 'PrimaryFill';
		B.ButtonText = "Fill";
		break;
	case 2:
		B.ID = 'Secondary';
		B.ButtonText = "Buy ";
		break;
	case 3:
		B.ID = 'SecondaryFill';
		B.ButtonText = "Fill";
		break;
	case 4:
		B.ID = 'Special';
		B.ButtonText = "Buy ";
		break;
	case 5:
		B.ID = 'SpecialFill';
		B.ButtonText = "Fill";
		break;
	}
	
	B.TextColor = ButtonTextColor;
	ToolTipStr = "Buy Ammo";
	B.ToolTip = ToolTipStr;
	B.OnClickLeft = ButtonClicked;
	B.OnClickRight = ButtonClicked;
	B.XPosition = X;
	B.XSize = W;
	B.YPosition = Y;
	B.YSize = H;
	
	AddComponent(B);
	return B;
}

defaultproperties
{
	ItemBorder=0.11

	ButtonTextColor=(R=240, G=240, B=240, A=255)

	Begin Object Class=KFGUI_List Name=AmmoList
		ID="AmmoL"
		ListItemsPerPage=3
		bClickable=false
		bHideScrollbar=true
		bUseFocusSound=false
		bCanFocus=false
	End Object

	Components.Add(AmmoList)
}