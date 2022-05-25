Class PU_HoveringWeaponInfo extends Actor;

var PlayerController LocalController;
var ST_GUIController GUI;

var() name CanvasTextureParamName;

var MaterialInstanceConstant InfoMaterial;
var ScriptedTexture CanvasTexture;
var Color TextColor;
var float TextScale;
var int AlphaFade, usingOnRender;

var string NameString;
var bool bInRange, bWasIdle;

var() editinline const StaticMeshComponent Mesh;

function PostBeginplay()
{
	super.PostBeginPlay();

	LocalController = GetALocalPlayerController();
	GUI = class'ST_GUIController'.static.GetGUIController(LocalController);

	CanvasTexture = ScriptedTexture(class'ScriptedTexture'.static.Create(512, 512,, MakeLinearColor(0,0,0,0)));
	CanvasTexture.Render = OnRender;
	CanvasTexture.bNeedsTwoCopies = false;

	InfoMaterial = Mesh.CreateAndSetMaterialInstanceConstant(0);
	//InfoMaterial.SetParent(Material'ENG_EngineResources_MAT.Debugging.DebugRenderTargetMaterial');

	//InfoMaterial.SetParent(Material'FX_Mat_Lib.FX_Wep_Gun_M_MuzzleCorona_PM');
	//InfoMaterial.SetTextureParameterValue('MaterialExpressionTextureSampleParameterSubUV_0', CanvasTexture);
	
	//InfoMaterial.SetParent(Material'FX_Mat_Lib.FX_Wep_Gun_M_InstantTracer_PM');
	//InfoMaterial.SetTextureParameterValue('Tex2d-Tracer', CanvasTexture);

	InfoMaterial.SetParent(Material'WEP_Famas_EMIT.FX_Basic_Trans');
	InfoMaterial.SetTextureParameterValue('Tex2D_Diffuse', CanvasTexture);

	//Material'WEP_Famas_EMIT.FX_Basic_Trans' - Tex2D_Diffuse
	//Material'WEP_Gravity_Imploder_EMIT.FX_Basic_Trans' - Tex2D_Diffuse

	if(InfoMaterial == none)
		`log("ST_WeaponTile: InfoMaterial is None");
}

event Tick(float DeltaTime)
{
	if(bInRange)
	{
		AlphaFade = Min(AlphaFade + (DeltaTime * 255), 255);
	}
	else
	{
		AlphaFade = Max(AlphaFade - (DeltaTime * 255), 0);
	}

	if(AlphaFade > 0)
	{
		if(bWasIdle)
			SnapRotate();
		bWasIdle = false;
		Rotate(DeltaTime);
	}
	else
	{
		bWasIdle = true;
	}
}

function Rotate(float DeltaTime)
{
	local Rotator TargetRot;

	TargetRot = Rotator(LocalController.Pawn.Location - Location);
	TargetRot.Pitch /= 2.0f;
	SetRotation(RInterpTo(Rotation, TargetRot, DeltaTime, 3.0f));
}

function SnapRotate()
{
	local Rotator TargetRot;

	TargetRot = Rotator(LocalController.Pawn.Location - Location);
	TargetRot.Pitch /= 2.0f;
	SetRotation(TargetRot);
}

function OnRender(Canvas C)
{
	if(usingOnRender == 0)
	{
		`log("ST_WeaponTile: OnRender() has been called");
	}
	else if(usingOnRender == 10)
	{
		`log("ST_WeaponTile: OnRender() is being repeatedly called");
	}
	++usingOnRender;

	if(AlphaFade == 0)
		return;

	//GUI.CurrentStyle.RenderWeaponTile(C);
	C.Font = GUI.CurrentStyle.PickFont(TextScale, FONT_NAME);
	C.SetDrawColor(255, 255, 255, 255);
	C.SetPos(0, 0);
	C.DrawText("Hovering Text",, TextScale, TextScale);

	CanvasTexture.bNeedsUpdate = true;
}

defaultproperties
{
	NameString="Weapon Name"
	TextColor=(R=236, G=227, B=203, A=255)
	bIgnoreBaseRotation=true
	Physics=PHYS_None
	usingOnRender=0

	Begin Object class=StaticMeshComponent Name=HoveringInfo
		StaticMesh=StaticMesh'SentryHammer.Mesh.Hovering_Info'
	End Object

	Mesh=HoveringInfo
	Components.Add(HoveringInfo)
}