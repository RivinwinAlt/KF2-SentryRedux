Class KFGUI_GridComponent extends KFGUI_MultiComponent;

var() float DividerSizes[2], XRes, YRes; // Pixels wide for dividers (Left/right, Up/Down)
var int GridCellsWide, GridCellsTall;
var bool bDataInitialized;

struct GridPosition
{
	var int CellX, CellY, CellsWide, CellsTall;
};
var array<GridPosition> PositionData;

function AddComponent(KFGUI_Base C, optional int X = 0, optional int Y = 0, optional int W = 1, optional int H = 1)
{
	local GridPosition NewPos;

	// Build grid position data for the component (Doesnt support removing components at this time)
	NewPos.CellX = X;
	NewPos.CellY = Y;
	NewPos.CellsWide = W;
	NewPos.CellsTall = H;
	PositionData.AddItem(NewPos);

    super.AddComponent(C);
}

function DrawComponents()
{
	local int i;

	// Calculate Pixels per Cell in terms of X and Y
	XRes = (CompPos[2] - ((GridCellsWide - 1) * DividerSizes[0])) / GridCellsWide;
	YRes = (CompPos[3] - ((GridCellsWide - 1) * DividerSizes[1])) / GridCellsTall;

    for(i=0; i<Components.Length; ++i)
    {
        Components[i].Canvas = Canvas;
        Components[i].InputPos[0] = CompPos[0] + XRes * PositionData[i].CellX + PositionData[i].CellX  * DividerSizes[0];
        Components[i].InputPos[1] = CompPos[1] + YRes * PositionData[i].CellY + PositionData[i].CellY * DividerSizes[1];
        Components[i].InputPos[2] = XRes * PositionData[i].CellsWide + (PositionData[i].CellsWide - 1) * DividerSizes[0];
        Components[i].InputPos[3] = YRes * PositionData[i].CellsTall + (PositionData[i].CellsTall - 1) * DividerSizes[1];
        
        Components[i].PreDraw();
    }
}

defaultproperties
{
	DividerSizes[0]=10 // Horizontal pixels between components
	DividerSizes[1]=10 // Vertical pixels between components
	GridCellsWide=1
	GridCellsTall=1
}