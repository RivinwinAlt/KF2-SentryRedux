Class UIP_Debug extends KFGUI_MultiComponent;

var KFGUI_TextField TF;
var float UpdatePeriod;
var SentryUI_Network SN;

function InitMenu()
{
    TF = KFGUI_TextField(FindComponentID('DebugText'));

    Super.InitMenu();
}

function RefreshVariables()
{
    TF.SetText(SimClientUpdate() $ "| |" $ SimServerUpdate() $ "| |" $ DirectCallUpdate());
}

reliable client function string SimClientUpdate()
{
    local string str;

    str = "Simulated Client Variables:";
    str $= "|  SN Name: " $ SN.Name;
    str $= "|  SN PlayerName: " $ SN.PlayerOwner.PlayerReplicationInfo.PlayerName;
    str $= "|  Turret Worth: " $ SN.TurretOwner.SentryWorth;
    str $= "|  Turret Upgrade Count: " $ SN.TurretOwner.UpgradesObj.AvailableUpgrades.Length;
    str $= "|  Player Dosh: " $ SN.PlayerOwner.PlayerReplicationInfo.Score;

    return str;
}

reliable server function string SimServerUpdate()
{
    local string str;

    str = "Simulated Server Variables:";
    str $= "|  SN Name: " $ SN.Name;
    str $= "|  SN PlayerName: " $ SN.PlayerOwner.PlayerReplicationInfo.PlayerName;
    str $= "|  Turret Worth: " $ SN.TurretOwner.SentryWorth;
    str $= "|  TurretUpgradeCount: " $ SN.TurretOwner.UpgradesObj.AvailableUpgrades.Length;
    str $= "|  Player Dosh: " $ SN.PlayerOwner.PlayerReplicationInfo.Score;

    return str;
}

function string DirectCallUpdate()
{
    local string str;

    str = "Direct-Access Variables:";
    str $= "|  SN Name: " $ SN.Name;
    str $= "|  SN PlayerName: " $ SN.PlayerOwner.PlayerReplicationInfo.PlayerName;
    str $= "|  Turret Worth: " $ SN.TurretOwner.SentryWorth;
    str $= "|  TurretUpgradeCount: " $ SN.TurretOwner.UpgradesObj.AvailableUpgrades.Length;
    str $= "|  Player Dosh: " $ SN.PlayerOwner.PlayerReplicationInfo.Score;

    return str;
}

function ShowMenu()
{
    SN = class'SentryUI_Network'.static.GetNetwork(GetPlayer());
    SetTimer(UpdatePeriod, true, 'RefreshVariables');

    super.ShowMenu();
}

function DoClose()
{
    ClearTimer('RefreshVariables');

    super.DoClose();
}

defaultproperties
{
    UpdatePeriod = 0.5f

    Begin Object Class=KFGUI_TextField Name=AboutText
        ID="DebugText"
        XPosition=0.025
        YPosition=0.025
        XSize=0.95
        YSize=0.8
        Text="Variable Info:"
    End Object
    
    Components.Add(AboutText)
}