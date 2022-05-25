Class UIG_UpgradesGrid extends KFGUI_GridComponent;

var UIR_UpgradesList UpgradeBox;
var UIR_AmmoListContainer AmmoList;
var UIR_TurretInfoContainer TurretStatus;

function InitMenu()
{
	Super.InitMenu();

	UpgradeBox = new (Self) class'UIR_UpgradesList';
	UpgradeBox.ID='UpgradeListID';
	UpgradeBox.XPosition=0.0;
	UpgradeBox.YPosition=0.0;
	UpgradeBox.XSize=1.0;
	UpgradeBox.YSize=1.0;
	UpgradeBox.WindowTitle="Upgrade List";
	AddComponent(UpgradeBox, 0, 0, 1, 2); // X, Y, W, H

	AmmoList = new (Self) class'UIR_AmmoListContainer';
	AmmoList.ID='AmmoListID';
	AmmoList.XPosition=0.0;
	AmmoList.YPosition=0.0;
	AmmoList.XSize=1.0;
	AmmoList.YSize=1.0;
	AmmoList.WindowTitle="Ammo List";
	AddComponent(AmmoList, 1, 0, 1, 1); // X, Y, W, H

	TurretStatus = new (Self) class'UIR_TurretInfoContainer';
	TurretStatus.ID='TurretInfoID';
	TurretStatus.XPosition=0.0;
	TurretStatus.YPosition=0.0;
	TurretStatus.XSize=1.0;
	TurretStatus.YSize=1.0;
	TurretStatus.WindowTitle="Turret Info";
	AddComponent(TurretStatus, 1, 1, 1, 1); // X, Y, W, H
}

defaultproperties
{
}