Class UIP_Upgrades extends KFGUI_MultiComponent;

var UIR_UpgradesList UpgradeBox;
var UIR_UpgradeEffectContainer UpgradeEffects;
var UIR_TurretInfoContainer TurretStatus;

function InitMenu()
{
    UpgradeBox = UIR_UpgradesList(FindComponentID('UpgradeBox'));
    UpgradeEffects = UIR_UpgradeEffectContainer(FindComponentID('UpgradeEffects'));
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
    
    SetTimer(0.f);
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
        XSize=0.465
        YSize=1.08
        WindowTitle="Upgrade List"
    End Object  
    
    Begin Object Class=UIR_UpgradeEffectContainer Name=UpgradeEffectsList
        ID="UpgradeEffects"
        XPosition=0.49
        YPosition=0
        XSize=0.48
        YSize=0.53
        WindowTitle="Upgrade Effects"
    End Object
    
    Begin Object Class=UIR_TurretInfoContainer Name=TurretInfo
        ID="TurretStatus"
        XPosition=0.49
        YPosition=0.55
        XSize=0.48
        YSize=0.53
        WindowTitle="Turret Status"
    End Object
    
    Components.Add(UpgradesList)
    Components.Add(UpgradeEffectsList)
    Components.Add(TurretInfo)
}