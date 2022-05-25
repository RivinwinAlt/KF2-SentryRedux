Class UIR_SettingsContainer extends KFGUI_Frame;

var KFGUI_CategoryList CatList;

function InitMenu()
{
	CatList = KFGUI_CategoryList(FindComponentID('SettingsList'));
	Super.InitMenu();

	CatList.AddCategory('Main', "Main", , true);
	CatList.AddCategory('Secondary', "Secondary", 2);
	CatList.AddCategory('Third', "A Random String well Make Show Up");
	CatList.AddCategory('Admin', "Test 4");

	AddCheckBox('Main', "Light HUD","Show a light version of the HUD.",'bLight',true);
    AddCheckBox('Main', "Show weapon info","Show current weapon ammunition status.",'bWeapons',false);
    AddCheckBox('Main', "Show personal info","Display health and armor on the HUD.",'bPersonal',true);
    AddCheckBox('Main', "Show score","Check to show scores on the HUD.",'bScore',false);
    AddCheckBox('Main', "Show kill counter","Tally specimen kills on the HUD.",'bTallySpecimenKills',true);
    AddCheckBox('Main', "Show damage counter","Tally specimen damage on the HUD.",'bHideDamageMsg',false);
    AddCheckBox('Main', "Show player deaths","Shows when a player dies.",'bHidePlayerDeathMsg',true);
    AddCheckBox('Main', "Show hidden player icons","Shows the hidden player icons.",'bDisableHiddenPlayers',false);
    AddCheckBox('Secondary', "Show damage messages","Shows the damage popups when damaging ZEDs.",'bEnableDamagePopups',true);
    AddCheckBox('Secondary', "Show regen on player info","Shows the bar next to players health when healed.",'bDrawRegenBar',false);
    AddCheckBox('Secondary', "Show player speed","Shows how fast you are moving.",'bShowSpeed',true);
    AddCheckBox('Secondary', "Show pickup information","Shows a UI with infromation on pickups.",'bDisablePickupInfo',false);
    AddCheckBox('Secondary', "Show lockon target","Shows who you have targeted with a medic gun.",'bDisableLockOnUI',true);
    AddCheckBox('Admin', "Show medicgun recharge info","Shows what the recharge info is on various medic weapons.",'bDisableRechargeUI',false);
    AddCheckBox('Admin', "Show last remaining ZED icons","Shows the last remaining ZEDs as icons.",'bDisableLastZEDIcons',true);
    AddCheckBox('Admin', "Show XP earned","Shows when you earn XP.",'bShowXPEarned',false);
    AddCheckBox('Third', "Disable classic trader voice","Disable the classic trader voice and portrait.",'bDisableClassicTrader',true);
    AddCheckBox('Third', "Disable classic music","Disable the classic music.",'bDisableClassicMusic',false);
    AddCheckBox('Third', "Enable B&W ZED Time","Enables the black and white fade to ZED Time.",'bEnableBWZEDTime',true);
    AddCheckBox('Admin', "Enable Modern Scoreboard","Makes the scoreboard look more modern.",'bModernScoreboard',false);
    AddCheckBox('Admin', "Disallow others to pickup your weapons","Disables other players ability to pickup your weapons.",'bDisallowOthersToPickupWeapons',true);
    AddCheckBox('Admin', "Disable console replacment","Disables the console replacment.",'bNoConsoleReplacement',false);
	
	AddButton('Admin', "BTestA","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Admin', "BTestB","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Admin', "BTestC","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Admin', "BTestD","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Admin', "BTestE","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Admin', "BTestF","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Third', "BTestG","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Third', "BTestH","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Third', "BTestI","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
	AddButton('Third', "BTestJ","Reset HUD Colors","Resets the color settings for the HUD.",'ResetColors');
}

function DrawMenu()
{
	super.DrawMenu();
}

final function KFGUI_CheckBox AddCheckBox( name CatID, string Cap, string TT, name IDN, bool bDefault )
{
    local KFGUI_CheckBox CB;
    
    CB = KFGUI_CheckBox(CatList.AddItemToCategory(CatID, class'KFGUI_CheckBox'));
    CB.LableString = Cap;
    CB.ToolTip = TT;
    CB.bChecked = bDefault;
    CB.InitMenu();
    CB.ID = IDN;
    CB.OnCheckChange = CheckChange;
    return CB;
}
final function KFGUI_Button AddButton( name CatID, string ButtonText, string Cap, string TT, name IDN)
{
    local KFGUI_Button CB;
    local KFGUI_MultiComponent MC;
    local KFGUI_TextLable Label;
    
    MC = KFGUI_MultiComponent(CatList.AddItemToCategory(CatID, class'KFGUI_MultiComponent'));
    MC.InitMenu();
    Label = new(MC) class'KFGUI_TextLable';
    Label.SetText(Cap);
    Label.XSize = 0.60;
    Label.FontScale = 1;
    Label.AlignY = 1;
    MC.AddComponent(Label);
    CB = new(MC) class'KFGUI_Button';
    CB.XPosition = 0.77;
    CB.XSize = 0.15;
    CB.ButtonText = ButtonText;
    CB.ToolTip = TT;
    CB.ID = IDN;
    CB.OnClickLeft = ButtonClicked;
    CB.OnClickRight = ButtonClicked;
    MC.AddComponent(CB);

    return CB;
}

function OnComboChanged(KFGUI_ComboBox Sender)
{
}

function CheckChange( KFGUI_CheckBox Sender )
{
}

function ButtonClicked( KFGUI_Button Sender )
{
}

function ScrollMouseWheel( bool bUp )
{
    CatList.ScrollBar.ScrollMouseWheel(bUp);
}

defaultproperties
{
	Begin Object Class=KFGUI_CategoryList Name=SettingsList
		ID="SettingsList"
		XPosition=0.0
		YPosition=0.0
		XSize=1.0
		YSize=1.0
        ListItemsPerPage=15
	End Object
	
	Components.Add(SettingsList)
}