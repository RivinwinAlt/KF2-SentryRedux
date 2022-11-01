Class UIR_SettingsContainer extends KFGUI_Frame;

var KFGUI_CategoryList CatList;

function InitMenu()
{
	CatList = KFGUI_CategoryList(FindComponentID('SettingsList'));
	Super.InitMenu();

	if(Owner.CSettings == none)
		`log("UIR_SettingsContainer: CSettings is none");

	CatList.AddCategory('Client', "Client", , true);
	CatList.AddCategory('Server', "Server");

	AddCheckBox('Client', "Show Controls Overlay", "Wether to show the controls overlay for the engineer's wrench when held in game.", 'bShowControlsOverlay', Owner.CSettings.ShowControlsOverlay);
	
	AddButton('Server', "Orphan Turret","Removes the owner of the turret as if they'd disconnected.", "Removes the owner of the turret as if they'd disconnected.",'OrphanTurret');
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
	switch(Sender.ID){
		case 'bShowControlsOverlay':
			Owner.CSettings.SetShowControlsOverlay(Sender.bChecked);
			break;
	}
}

function ButtonClicked( KFGUI_Button Sender )
{
	switch(Sender.ID)
	{
		case 'OrphanTurret':
			`log("UIR_SettingsContainer: Pressed orphan button locally");
			if(Owner.NetworkObj != none)
			{
				`log("UIR_SettingsContainer: Orphaning turret");
				Owner.NetworkObj.Orphan();
			}
			else if(Owner == none)
			{
				`log("UIR_SettingsContainer: Cant access GUIController");
			}
			else
			{
				`log("UIR_SettingsContainer: SentryNetwork reference is none");
			}
			break;
	}
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