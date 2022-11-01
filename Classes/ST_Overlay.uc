// Handles drawing the info text for each turret during play
Class ST_Overlay extends Interaction;

var array<ST_Turret_Base> ActiveTurrets;
var PlayerController LocalPC;
var ST_GUIController GUI;
var transient KFGUI_StyleBase GUIStyle;
var transient ST_ClientSettings CSettings;
var FontRenderInfo DrawInfo;
var color OwnerColor, OtherColor;

var transient vector CamLocation, XDir;
var transient rotator CamRotation;
var transient float XL, YL, ZDepth;
var float TextScale;

// Ensure the player always has one instance of the overlay spawned
static final function ST_Overlay GetOverlay(PlayerController PC, WorldInfo Level)
{
	local Interaction I;
	local ST_Overlay S;

	if(Level == none || Level.NetMode == NM_DedicatedServer)
	{
		`log("ST_Overlay: WorldInfo not valid or on server");
		return none;
	}

	if(PC == none)
	{
		`log("ST_Overlay: PC is none");
		return none;
	}

	// Iterate through all available interactions and if one is a ST_Overlay return it
	foreach PC.Interactions(I)
	{
		S = ST_Overlay(I);
		if(S != None)
		{
			`log("ST_Overlay: Returning reference to existing object");
			return S;
		}
	}

	// If there isn't one create it
	`log("ST_Overlay: Creating new object");
	S = new (PC) class'ST_Overlay';
	S.LocalPC = PC;
	PC.Interactions.AddItem(S);
	
	S.GUI = Class'ST_GUIController'.Static.GetGUIController(PC);
	S.GUIStyle = S.GUI.CurrentStyle;
	if(S.GUIStyle == none)
		`log("ST_Overlay: GUIStyle = None");

	S.CSettings = Class'ST_ClientSettings'.Static.GetClientSettings(level);
	if(S.CSettings == none)
		`log("ST_Overlay: CSettings = None");

	S.Init();

	return S;
}



// Executes every frame after all actors are rendered in 3d
event PostRender(Canvas Canvas)
{
	local float FontScale, ZDist, Scale;
	local KFWeap_EngWrench Weap;
	local ST_Turret_Base S;
	local vector V;
	local string Str;

	// If the overlay isnt owned by a player (they disconnected/spectating) dont draw
	if(LocalPC == None || LocalPC.Pawn == None) //This mnakes the overlay invisible to spectators TODO:change
		return;

	// Get player perspective to calculate where and how large the text should be
	LocalPC.GetPlayerViewPoint(CamLocation, CamRotation);
	XDir = vector(CamRotation);
	ZDepth = CamLocation Dot XDir;

	// Check if the controls section has been turned off in the client settings
	if(CSettings.ShowControlsOverlay)
	{
		// Check if the current weapon is a sentry hammer before rendering controls
		Weap = KFWeap_EngWrench(LocalPC.Pawn.Weapon);
		if(Weap != none && !GUI.bIsInMenuState)
			GUIStyle.RenderWrenchInfo(Weap);
	}

	// Get default overlay font variables
	FontScale = class'KFGameEngine'.Static.GetKFFontScale();
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
	
	foreach ActiveTurrets(S)
	{
		if(S.Health <= 0) // Filter by dead.
			continue;

		V = S.Location + vect(0, 0, 70); // Changes text location to be head height instead of on the ground

		// TODO: benchmark this math against native implementations
		ZDist = (V Dot XDir) - ZDepth; // Calculate distance to turret

		if(ZDist<1.f || ZDist>1000.f) // Filter by distance.
			continue;

		V = Canvas.Project(V); // Calculates screen placement.
		if(V.X<0.f || V.Y<0.f || V.X>Canvas.ClipX || V.Y>Canvas.ClipY) // Filter by screen bounds.
			continue;
		
		// Scales the font by distance to turret
		Scale = FontScale * TextScale * (1.f - ZDist/1000.f); // Linear scale font size by distance.
		Canvas.Font = GUIStyle.NameFont; // InfiniteFont, NumberFont, NameFont, MainFont

		Canvas.DrawColor = (S.PlayerReplicationInfo == LocalPC.PlayerReplicationInfo) ? OwnerColor : OtherColor;
		Str = S.GetInfo(); // This returns the health and owner name
		Canvas.TextSize(Str, XL, YL, Scale, Scale); // Scale the text in both the x and y directions

		// This does two things: Centers the text on the turret, and makes closer turrets overlay further ones.
		Canvas.SetPos(V.X - (XL * 0.5), V.Y - (YL * 0.5), 0.25f/(ZDist + 1.f));
		Canvas.DrawText(Str, , Scale, Scale, DrawInfo); // Draw the text on screen
		
		// If the Turret is closer than 600 draw additional text
		if(ZDist<600.f)
		{
			V.Y += YL; // This line kicks the draw point down below the previously drawn text
			Str = S.GetAmmoStatus();
			Canvas.TextSize(Str, XL, YL, Scale, Scale);
			Canvas.SetPos(V.X - (XL * 0.5), V.Y - (YL * 0.5), Canvas.CurZ);
			Canvas.DrawText(Str, , Scale, Scale, DrawInfo);
		}
	}
}

defaultproperties
{
	TextScale = 1.5
	DrawInfo = (bClipText = True, bEnableShadow = True, GlowInfo = (GlowColor = (R = 0.000000, G = 0.000000, B = 0.000000, A = 1.000000)))
	OwnerColor = (B = 48, G = 255, R = 48, A = 255)
	OtherColor = (B = 48, G = 200, R = 255, A = 255)
}
