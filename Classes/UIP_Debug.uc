Class UIP_Debug extends KFGUI_MultiComponent;

var KFGUI_Button BenchmarkButton;
var KFGUI_TextScroll SettingsBlock;
var Benchmarker BM;
var ST_Settings_Rep Settings;

function InitMenu()
{
	Super.InitMenu();

	Settings = class'ST_Settings_Rep'.Static.GetSettings(Owner.PlayerOwner.WorldInfo);
	BM = Owner.PlayerOwner.Spawn(class'Benchmarker');

	BenchmarkButton = AddButton("Run Benchmarks", 'BenchmarkB', , 0.0, 0.0);
	SettingsBlock = AddTextBlock(FetchSettingsString(), 'CurrentSettings', 0.0, 0.1, 1.0, 0.9);
	
	AddComponent(BenchmarkButton);
	AddComponent(SettingsBlock);

	SetTimer(1.0, true, 'UpdateDebugInfo');
}

function UpdateDebugInfo()
{
	SettingsBlock.SetText(FetchSettingsString());
}

function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'BenchmarkB':
		BM.RunAllBenchmarks();
		break;
	}
}

final function KFGUI_Button AddButton( string ButtonText, name IDN, optional string TT = "It's a button!", optional float newXPos = 0, optional float newYPos = 0, optional float newXSize = 0.2, optional float newYSize = 0.05)
{
	local KFGUI_Button B;

	B = new(Self) class'KFGUI_Button';
	B.XPosition = newXPos;
	B.YPosition = newYPos;
	B.XSize = newXSize;
	B.YSize = newYSize;
	B.ButtonText = ButtonText;
	B.ToolTip = TT;
	B.ID = IDN;
	B.OnClickLeft = ButtonClicked;
	B.OnClickRight = ButtonClicked;

	return B;
}
final function KFGUI_TextScroll AddTextBlock(String Cap, name IDN, optional float newXPos = 0, optional float newYPos = 0, optional float newXSize = 1, optional float newYSize = 1)
{
	local KFGUI_TextScroll TS;

	TS = new(Self) class'KFGUI_TextScroll';
	TS.ID = IDN;
	TS.XPosition = newXPos;
	TS.YPosition = newYPos;
	TS.XSize = newXSize;
	TS.YSize = newYSize;
	TS.SetText(Cap);

	return TS;
}

function String FetchSettingsString()
{
	local String RtnString;

	RtnString $= Settings.NumMapTurrets $ " / " $ Settings.repMaxMap $ " : Turrets On Map|";
	RtnString $= Settings.NumPlayerTurrets $ " / " $ Settings.repMaxPlayer $ " : Turrets Owned by Player|";
	//RtnString $= Settings.VariableName $ ": Description|";

	return RtnString;
}

defaultproperties
{
}