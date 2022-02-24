// Handles drawing the info text for each turret during play

Class SentryOverlay extends Interaction;

var array<ST_Base> ActiveTurrets;
var PlayerController LocalPC;
var FontRenderInfo DrawInfo;
var color OwnerColor, OtherColor;

var transient vector CamLocation, XDir;
var transient rotator CamRotation;
var transient float XL, YL, ZDepth;

// Ensure the player always has one instance of the overlay spawned
static final function SentryOverlay GetOverlay(PlayerController PC)
{
	local Interaction I;
	local SentryOverlay S;

	// Iterate through all available interactions and if one is a SentryOverlay return it
	foreach PC.Interactions(I)
	{
		S = SentryOverlay(I);
		if(S != None)
			return S;
	}
	// If there isnt one create it
	S = new (PC) class'SentryOverlay';
	S.LocalPC = PC;
	PC.Interactions.AddItem(S);
	S.Init();
	return S;
}

// Executes every frame after all actors are rendered in 3d
event PostRender(Canvas Canvas)
{
	local float FontScale, ZDist, Scale;
	local KFWeap_EngWrench W;
	local ST_Base S;
	local vector V;
	local string Str;

	// If the overlay isnt owned by a player (they disconnected/spectating) dont draw
	if(LocalPC == None || LocalPC.Pawn == None) //This mnakes the overlay invisible to spectators TODO:change
		return;

	// Get player perspective to calculate where and how large the text should be
	LocalPC.GetPlayerViewPoint(CamLocation, CamRotation);
	XDir = vector(CamRotation);
	ZDepth = CamLocation Dot XDir;

	// Get default overlay font variables
	FontScale = class'KFGameEngine'.Static.GetKFFontScale();
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
	
	// If holding a sentry hammer draw associated overlay
	W = KFWeap_EngWrench(LocalPC.Pawn.Weapon);
	if(W != None)
		W.DrawInfo(Canvas, FontScale);
	
	foreach ActiveTurrets(S)
	{
		if(S.Health <= 0) // Filter by dead.
			continue;
		V = S.Location + vect(0, 0, 70); // Changes text location to be head height instead of on the ground
		ZDist = (V Dot XDir) - ZDepth; // Calculate distance to turret
		if(ZDist<1.f || ZDist>1000.f) // Filter by distance.
			continue;
		V = Canvas.Project(V); // Calculates screen placement.
		if(V.X<0.f || V.Y<0.f || V.X>Canvas.ClipX || V.Y>Canvas.ClipY) // Filter by screen bounds.
			continue;
		
		// Scales the font by distance to turret
		Scale = FontScale * 2.f * (1.f - ZDist/1000.f); // Linear scale font size by distance.

		// This '?' is a fast if() statement, it sets the color based on whether the player owns the turret
		Canvas.DrawColor = (S.PlayerReplicationInfo == LocalPC.PlayerReplicationInfo) ? OwnerColor : OtherColor;
		Str = S.GetInfo(); // This returns the health and owner name
		Canvas.TextSize(Str, XL, YL, Scale, Scale); // Scale the text in both the x and y directions

		// This does two things: Centers the text on the turret, and makes closer turrets overlay further ones.
		Canvas.SetPos(V.X - (XL * 0.5), V.Y - (YL * 0.5), 0.25f/(ZDist + 1.f));
		Canvas.DrawText(Str, , Scale, Scale, DrawInfo); // Draw the text on screen
		
		// If the Turret is closer than 600 draw additional text
		if(ZDist<600.f)
		{
			// This line kicks the draw point down below the previously drawn text
			V.Y += YL;
			Str = S.GetAmmoStatus();
			Canvas.TextSize(Str, XL, YL, Scale, Scale);
			Canvas.SetPos(V.X - (XL * 0.5), V.Y - (YL * 0.5), Canvas.CurZ);
			Canvas.DrawText(Str, , Scale, Scale, DrawInfo);
		}
		
		// If the turret is closer than 100 draw some interaction text
		if(ZDist<100.f)
		{
			V.Y += (YL * 0.5);
			Str = "[Use] for options";
			Scale *= 0.75;
			Canvas.TextSize(Str, XL, YL, Scale, Scale);
			Canvas.SetPos(V.X - (XL * 0.5), V.Y, Canvas.CurZ);
			Canvas.DrawText(Str, , Scale, Scale, DrawInfo);
		}
	}
}

defaultproperties
{
   DrawInfo = (bClipText = True, bEnableShadow = True, GlowInfo = (GlowColor = (R = 0.000000, G = 0.000000, B = 0.000000, A = 1.000000)))
   OwnerColor = (B = 48, G = 255, R = 48, A = 255)
   OtherColor = (B = 48, G = 200, R = 255, A = 255)
}
