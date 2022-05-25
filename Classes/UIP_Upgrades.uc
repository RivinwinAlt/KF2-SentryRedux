Class UIP_Upgrades extends KFGUI_MultiComponent;

var UIG_UpgradesGrid UpgradeGrid;

function InitMenu()
{
	UpgradeGrid = UIG_UpgradesGrid(FindComponentID('UpgradesGrid'));

	Super.InitMenu();
}

defaultproperties
{
	Begin Object Class=UIG_UpgradesGrid Name=UpGrid
		ID="UpgradesGrid"
		XPosition=0
		YPosition=0
		XSize=1.0
		YSize=1.0
		DividerSizes[0]=20
    	DividerSizes[1]=20
    	GridCellsWide=2
    	GridCellsTall=2
    End Object
	
	Components.Add(UpGrid)
}