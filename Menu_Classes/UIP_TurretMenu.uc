Class UIP_TurretMenu extends KFGUI_MultiComponent;

var UIR_PerkInfoContainer PerkInfoBox;
var UIR_PerkEffectContainer PerkEffectList;
var UIR_LevelRequirementsList NextLevelRequirementList;
var ClassicPerk_Base SelectedPerk;
var PlayerController PC;

function InitMenu()
{
    UpgradesContainer = UIR_PerkInfoContainer(FindComponentID('UpgradesList'));
    UpgradeStatsList = UIR_PerkEffectContainer(FindComponentID('UpgradeStats'));
    TurretStatsList = UIR_LevelRequirementsList(FindComponentID('TurretStats'));
    
    //PC = ClassicPlayerController(GetPlayer());
    PC = GetPlayer();
    //PC.PerkSelectionBox = Self;
    
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
    
    UpgradesContainer.FrameTex = Owner.CurrentStyle.BorderTextures[`BOX_MEDIUM_SLIGHTTRANSPARENT];
    UpgradeStatsList.FrameTex = Owner.CurrentStyle.BorderTextures[`BOX_MEDIUM_SLIGHTTRANSPARENT];
    TurretStatsList.FrameTex = Owner.CurrentStyle.BorderTextures[`BOX_MEDIUM_SLIGHTTRANSPARENT];
    
    bTextureInit = true;
}

defaultproperties
{
    Begin Object Class=UIR_PerkInfoContainer Name=UpgradesContainer
        ID="UpgradesList"
        XPosition=0
        YPosition=0
        XSize=0.465
        YSize=1.08
        WindowTitle="Click Upgrade to get Details"
    End Object  
    
    Begin Object Class=UIR_PerkEffectContainer Name=UpgradeStatsList
        ID="UpgradeStats"
        XPosition=0.49
        YPosition=0
        XSize=0.48
        YSize=0.53
        WindowTitle="Upgrade Stats"
    End Object
    
    Begin Object Class=UIR_LevelRequirementsList Name=TurretStatsList
        ID="TurretStats"
        XPosition=0.49
        YPosition=0.55
        XSize=0.48
        YSize=0.53
        WindowTitle="Turret Stats"
    End Object
    
    Components.Add(UpgradesContainer)
    Components.Add(UpgradeStatsList)
    Components.Add(TurretStatsList)
}