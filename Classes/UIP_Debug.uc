Class UIP_Debug extends KFGUI_MultiComponent;

var KFGUI_Button BenchmarkButton;
var Benchmarker BM;

function InitMenu()
{
    Super.InitMenu();

    BM = Owner.PlayerOwner.Spawn(class'Benchmarker');

    BenchmarkButton = new (Self) class'KFGUI_Button';
    BenchmarkButton.ButtonText = "Run Benchmark";
    BenchmarkButton.OnClickLeft = ButtonClicked;
    BenchmarkButton.OnClickRight = ButtonClicked;
    BenchmarkButton.ID = 'BenchmarkB';
    BenchmarkButton.XPosition = 0.1f;
    BenchmarkButton.XSize = 0.3f;
    BenchmarkButton.YPosition = 0.1f;
    BenchmarkButton.YSize = 0.1f;

    AddComponent(BenchmarkButton);
}

function ButtonClicked( KFGUI_Button Sender )
{
    BM.RunAllBenchmarks();
}

defaultproperties
{
}