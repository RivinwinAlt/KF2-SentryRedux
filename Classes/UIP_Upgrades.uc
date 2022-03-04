Class UIP_Upgrades extends KFGUI_MultiComponent;

var UIR_UpgradesList UpgradeBox;
var UIR_AmmoListContainer UpgradeEffects;
var UIR_TurretInfoContainer TurretStatus;

function InitMenu()
{
	UpgradeBox = UIR_UpgradesList(FindComponentID('UpgradeBox'));
	UpgradeEffects = UIR_AmmoListContainer(FindComponentID('UpgradeEffects'));
	TurretStatus = UIR_TurretInfoContainer(FindComponentID('TurretStatus'));

	SetTimer(0.1, true);
	
	Super.InitMenu();
}

function Timer()
{
	if( !bTextureInit )
	{
		GetStyleTextures();
		return;
	}
	
	SetTimer(0.f, false);
}

function GetStyleTextures()
{
	if( !Owner.bFinishedReplication )
	{
		return;
	}
	
	UpgradeBox.FrameTex = Owner.CurrentStyle.BorderTextures[`BOX_SMALL_SLIGHTTRANSPARENT];
	UpgradeEffects.FrameTex = Owner.CurrentStyle.BorderTextures[`BOX_SMALL_SLIGHTTRANSPARENT];
	TurretStatus.FrameTex = Owner.CurrentStyle.BorderTextures[`BOX_SMALL_SLIGHTTRANSPARENT];
	
	bTextureInit = true;
}

defaultproperties
{
	Begin Object Class=UIR_UpgradesList Name=UpgradesList
		ID="UpgradeBox"
		XPosition=0
		YPosition=0
		XSize=0.5
		YSize=1.08
		WindowTitle="Upgrade List"
	End Object  
	
	Begin Object Class=UIR_AmmoListContainer Name=UpgradeEffectsList
		ID="UpgradeEffects"
		XPosition=0.5
		YPosition=0
		XSize=0.5
		YSize=0.54
		WindowTitle="Ammo"
	End Object
	
	Begin Object Class=UIR_TurretInfoContainer Name=TurretInfo
		ID="TurretStatus"
		XPosition=0.5
		YPosition=0.5
		XSize=0.5
		YSize=0.54
		WindowTitle="Turret Status"
	End Object
	
	Components.Add(UpgradesList)
	Components.Add(UpgradeEffectsList)
	Components.Add(TurretInfo)
}