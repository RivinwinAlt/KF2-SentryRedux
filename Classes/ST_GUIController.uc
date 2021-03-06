Class ST_GUIController extends Info
	transient;

var() class<KFGUI_StyleBase> DefaultStyle;

var PlayerController PlayerOwner;
var transient KFGUI_Input CustomInput;
var transient PlayerInput BackupInput;
var transient GameViewportClient ClientViewport;

var delegate<Interaction.OnReceivedNativeInputKey> OldOnReceivedNativeInputKey;
var delegate<Interaction.OnReceivedNativeInputAxis> OldOnReceivedNativeInputAxis;
var delegate<Interaction.OnReceivedNativeInputChar> OldOnReceivedNativeInputChar;

var delegate<GameViewportClient.HandleInputAxis> OldHandleInputAxis;

var array<KFGUI_Page> ActiveMenus, PersistentMenus;
var array<KFGUI_OverlayComponent> Overlays;
var transient KFGUI_Base MouseFocus,InputFocus,KeyboardFocus;
var IntPoint MousePosition,ScreenSize,OldMousePos,LastMousePos,LastClickPos[2];
var transient float MousePauseTime,MenuTime,LastClickTimes[2];
var transient KFGUI_StyleBase CurrentStyle;

var transient Console OrgConsole;
var transient KFGUIConsoleHack HackConsole;

var bool bMouseWasIdle,bIsInMenuState,bAbsorbInput,bIsInvalid,bFinishedReplication,bUsingGamepad,bForceEngineCursor,bNoInputReset;

var ObjectReferencer RepObject, RepIcons; // Hacked in objectreferencer for direct referencing
var ST_Turret_Base TurretOwner;
var ST_SentryNetwork NetworkObj;

static function ST_GUIController GetGUIController( PlayerController PC )
{
	local ST_GUIController G;

	if( PC.Player==None )
		return None;
		
	foreach PC.ChildActors(class'ST_GUIController',G)
	{
		if( !G.bIsInvalid )
			break;
	}
	
	if( G==None )
		G = PC.Spawn(class'ST_GUIController',PC);
		
	return G;
}

simulated function PostBeginPlay()
{
	PlayerOwner = PlayerController(Owner);
	if(PlayerOwner == none)
		`log("ST_GUIController: PlayerOwner is Null in PostBeginPlay()");
	ClientViewport = LocalPlayer(PlayerOwner.Player).ViewportClient;
	
	CurrentStyle = new (None) DefaultStyle;
	CurrentStyle.InitStyle();
	CurrentStyle.Owner = self;
	
	SetTimer(0.25, true, 'SetupStyleTextures');
	SetupStyleTextures();
}

simulated function SetupStyleTextures()
{
	if( RepObject != None )
	{
		CurrentStyle.NameFont = Font(RepObject.ReferencedObjects[27]);
		CurrentStyle.MainFont = Font(RepObject.ReferencedObjects[26]);
		CurrentStyle.NumberFont = Font(RepObject.ReferencedObjects[28]);
		
		CurrentStyle.BorderTextures[`BOX_INNERBORDER] = Texture2D(RepObject.ReferencedObjects[4]);
		CurrentStyle.BorderTextures[`BOX_SMALL] = Texture2D(RepObject.ReferencedObjects[21]);

		CurrentStyle.ArrowTextures[`ARROW_RIGHT] = Texture2D(RepObject.ReferencedObjects[0]);
		CurrentStyle.ArrowTextures[`ARROW_DOWN] = Texture2D(RepObject.ReferencedObjects[1]);
		CurrentStyle.ArrowTextures[`ARROW_LEFT] = Texture2D(RepObject.ReferencedObjects[2]);
		CurrentStyle.ArrowTextures[`ARROW_UP] = Texture2D(RepObject.ReferencedObjects[3]);

		CurrentStyle.ButtonTextures[`BUTTON_NORMAL] = Texture2D(RepObject.ReferencedObjects[32]);
		CurrentStyle.ButtonTextures[`BUTTON_HIGHLIGHTED] = Texture2D(RepObject.ReferencedObjects[33]);
		CurrentStyle.ButtonTextures[`BUTTON_PRESSED] = Texture2D(RepObject.ReferencedObjects[34]);
		CurrentStyle.ButtonTextures[`BUTTON_DISABLED] = Texture2D(RepObject.ReferencedObjects[35]);
		
		CurrentStyle.TabTextures[`TAB_TOP] = Texture2D(RepObject.ReferencedObjects[20]);
		
		CurrentStyle.ItemBoxTextures[`ITEMBOX_NORMAL] = Texture2D(RepObject.ReferencedObjects[8]);
		CurrentStyle.ItemBoxTextures[`ITEMBOX_DISABLED] = Texture2D(RepObject.ReferencedObjects[9]);
		CurrentStyle.ItemBoxTextures[`ITEMBOX_HIGHLIGHTED] = Texture2D(RepObject.ReferencedObjects[10]);
		
		CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_NORMAL] = Texture2D(RepObject.ReferencedObjects[5]);
		CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_DISABLED] = Texture2D(RepObject.ReferencedObjects[6]);
		CurrentStyle.ItemBoxTextures[`ITEMBOX_BAR_HIGHLIGHTED] = Texture2D(RepObject.ReferencedObjects[7]);
		
		CurrentStyle.CheckBoxTextures[`CHECKMARK_NORMAL] = Texture2D(RepObject.ReferencedObjects[29]);
		//CurrentStyle.CheckBoxTextures[`CHECKMARK_DISABLED] = Texture2D(RepObject.ReferencedObjects[5]);
		CurrentStyle.CheckBoxTextures[`CHECKMARK_HIGHLIGHTED] = Texture2D(RepObject.ReferencedObjects[30]);
		
		CurrentStyle.ScrollTexture = Texture2D(RepObject.ReferencedObjects[19]);
		
		CurrentStyle.ProgressBarTextures[`PROGRESS_BAR_NORMAL] = Texture2D(RepObject.ReferencedObjects[22]);
		CurrentStyle.ProgressBarTextures[`PROGRESS_BAR_SELECTED] = Texture2D(RepObject.ReferencedObjects[18]);

		CurrentStyle.SliderTextures[`SLIDER_NORMAL] = Texture2D(RepObject.ReferencedObjects[23]);
		CurrentStyle.SliderTextures[`SLIDER_GRIP] = Texture2D(RepObject.ReferencedObjects[24]);
		CurrentStyle.SliderTextures[`SLIDER_DISABLED] = Texture2D(RepObject.ReferencedObjects[25]);
		
		CurrentStyle.MenuDown = SoundCue(RepObject.ReferencedObjects[11]);
		CurrentStyle.MenuDrag = SoundCue(RepObject.ReferencedObjects[12]);
		CurrentStyle.MenuEdit = SoundCue(RepObject.ReferencedObjects[13]);
		CurrentStyle.MenuFade = SoundCue(RepObject.ReferencedObjects[14]);
		CurrentStyle.MenuClick = SoundCue(RepObject.ReferencedObjects[15]);
		CurrentStyle.MenuHover = SoundCue(RepObject.ReferencedObjects[16]);
		CurrentStyle.MenuUp = SoundCue(RepObject.ReferencedObjects[17]);

		CurrentStyle.WinHighlight = Texture2D(RepObject.ReferencedObjects[36]);
		CurrentStyle.ColumnSeparator = Texture2D(RepObject.ReferencedObjects[37]);

		CurrentStyle.IconLibrary[`ICON_DEFAULT] = Texture2D(RepIcons.ReferencedObjects[0]);
		CurrentStyle.IconLibrary[`ICON_AMMO_BULLETS] = Texture2D(RepIcons.ReferencedObjects[4]);
		CurrentStyle.IconLibrary[`ICON_AMMO_ROCKET] = Texture2D(RepIcons.ReferencedObjects[5]);
		CurrentStyle.IconLibrary[`ICON_LEVEL_1] = Texture2D(RepIcons.ReferencedObjects[1]);
		CurrentStyle.IconLibrary[`ICON_LEVEL_2] = Texture2D(RepIcons.ReferencedObjects[2]);
		CurrentStyle.IconLibrary[`ICON_LEVEL_3] = Texture2D(RepIcons.ReferencedObjects[3]);
		
		//CurrentStyle.CursorTextures[`CURSOR_DEFAULT] = Texture2D(RepObject.ReferencedObjects[31]);
		/*
		CursorTextures[`CURSOR_RESIZEVERT] = Texture2D(RepObject.ReferencedObjects[]);
		CursorTextures[`CURSOR_RESIZEHORZ] = Texture2D(RepObject.ReferencedObjects[]);
		*/
		
		bFinishedReplication = true;
		ClearTimer('SetupStyleTextures');
	}
}

simulated function Destroyed()
{
	if(PlayerOwner != None)
		SetMenuState(false);
}

simulated function SetTurret(ST_Turret_Base T)
{
	TurretOwner = T;
}

simulated function HandleDrawMenu()
{
	if( HackConsole==None )
	{
		HackConsole = new(ClientViewport)class'KFGUIConsoleHack';
		HackConsole.OutputObject = Self;
	}
	if( HackConsole!=ClientViewport.ViewportConsole )
	{
		OrgConsole = ClientViewport.ViewportConsole;
		ClientViewport.ViewportConsole = HackConsole;
		
		// Make sure nothing overrides these settings while menu is being open.
		PlayerOwner.PlayerInput = CustomInput;
	}
}

simulated function RenderMenu( Canvas C )
{
	local int i;
	local float OrgX, OrgY, ClipX, ClipY, WSOffset;
	
	if( !bFinishedReplication )
		return;

	//ClientViewport.ViewportConsole = OrgConsole;
	ScreenSize.X = C.SizeX;
	ScreenSize.Y = C.SizeY;
	CurrentStyle.Canvas = C;
	CurrentStyle.PickDefaultFontSize(C.SizeY);

	OrgX = C.OrgX;
	OrgY = C.OrgY;
	ClipX = C.ClipX;
	ClipY = C.ClipY;
	WSOffset = C.ClipX - (C.ClipY * 16.0f / 9.0f); // Ultra widescreen offset, brings us down to a consistant 16:9 ratio

	for(i = (ActiveMenus.Length - 1); i >= 0; --i) // TODO: optimize: move to foreach model
	{
		ActiveMenus[i].bWindowFocused = (i==0);
		ActiveMenus[i].InputPos[0] = WSOffset / 2.0f;
		ActiveMenus[i].InputPos[1] = 0.f;
		ActiveMenus[i].InputPos[2] = ScreenSize.X - WSOffset;
		ActiveMenus[i].InputPos[3] = ScreenSize.Y;
		ActiveMenus[i].Canvas = C;
		ActiveMenus[i].PreDraw();
	}
	if( InputFocus!=None && InputFocus.bFocusedPostDrawItem )
	{
		InputFocus.InputPos[0] = WSOffset / 2.0f;
		InputFocus.InputPos[1] = 0.f;
		InputFocus.InputPos[2] = ScreenSize.X - WSOffset;
		InputFocus.InputPos[3] = ScreenSize.Y;
		InputFocus.Canvas = C;
		InputFocus.PreDraw();
	}

	C.SetOrigin(OrgX, OrgY);
	C.SetClip(ClipX, ClipY);

	CurrentStyle.DrawCursor(MousePosition.X, MousePosition.Y);
}

simulated function RenderOverlays( Canvas C )
{
	local KFGUI_OverlayComponent TempOverlay;

	CurrentStyle.Canvas = C;

	foreach Overlays(TempOverlay)
	{
		if(TempOverlay.bEnabled)
		{
			TempOverlay.DrawOverlay();
		}
	}
}

simulated final function SetMenuState( bool bActive )
{
	if( PlayerOwner.PlayerInput==None )
	{
		NotifyLevelChange();
		bActive = false;
	}

	if( bIsInMenuState==bActive )
		return;
	bIsInMenuState = bActive;

	if( bActive )
	{
		if( CustomInput==None )
		{
			CustomInput = new (KFPlayerController(PlayerOwner)) class'KFGUI_Input';
			CustomInput.ControllerOwner = Self;
			CustomInput.OnReceivedNativeInputKey = ReceivedInputKey;
			CustomInput.BaseInput = PlayerOwner.PlayerInput;
			BackupInput = PlayerOwner.PlayerInput;
			PlayerOwner.Interactions.AddItem(CustomInput);
		}
		
		OldOnReceivedNativeInputKey = BackupInput.OnReceivedNativeInputKey;
		OldOnReceivedNativeInputAxis = BackupInput.OnReceivedNativeInputAxis;
		OldOnReceivedNativeInputChar = BackupInput.OnReceivedNativeInputChar;
		
		BackupInput.OnReceivedNativeInputKey = ReceivedInputKey;
		BackupInput.OnReceivedNativeInputAxis = ReceivedInputAxis;
		BackupInput.OnReceivedNativeInputChar = ReceivedInputChar;
		
		OldHandleInputAxis = ClientViewport.HandleInputAxis;
		ClientViewport.HandleInputAxis = ReceivedInputAxis;
		
		PlayerOwner.PlayerInput = CustomInput;

		if( LastMousePos != default.LastMousePos )
			ClientViewport.SetMouse(LastMousePos.X,LastMousePos.Y);
	}
	else
	{
		LastMousePos = MousePosition;
		
		ClientViewport.HandleInputAxis = None;
		
		if( BackupInput!=None )
		{
			BackupInput.OnReceivedNativeInputKey = OldOnReceivedNativeInputKey;
			BackupInput.OnReceivedNativeInputAxis = OldOnReceivedNativeInputAxis;
			BackupInput.OnReceivedNativeInputChar = OldOnReceivedNativeInputChar;
			PlayerOwner.PlayerInput = BackupInput;
			
			ClientViewport.HandleInputAxis = OldHandleInputAxis;
		}
		LastClickTimes[0] = 0;
		LastClickTimes[1] = 0;
	}
	
	if( !bNoInputReset )
	{
		PlayerOwner.PlayerInput.ResetInput();
	}
}

simulated function NotifyLevelChange()
{
	local int i;

	if( bIsInvalid )
		return;
	bIsInvalid = true;

	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}

	for( i=(ActiveMenus.Length-1); i>=0; --i )
		ActiveMenus[i].NotifyLevelChange();
	for( i=(PersistentMenus.Length-1); i>=0; --i )
		PersistentMenus[i].NotifyLevelChange();

	SetMenuState(false);
}

simulated function MenuInput(float DeltaTime)
{
	local int i;
	local vector2D V;

	if( PlayerOwner.PlayerInput==None )
	{
		NotifyLevelChange();
		return;
	}
	if( InputFocus!=None )
		InputFocus.MenuTick(DeltaTime);
	for( i=0; i<ActiveMenus.Length; ++i )
		ActiveMenus[i].MenuTick(DeltaTime);
	
	// Check idle.
	if( Abs(MousePosition.X-OldMousePos.X)>5.f || Abs(MousePosition.Y-OldMousePos.Y)>5.f || (bMouseWasIdle && MousePauseTime<0.5f) )
	{
		if( bMouseWasIdle )
		{
			bMouseWasIdle = false;
			if( InputFocus!=None )
				InputFocus.InputMouseMoved();
		}
		OldMousePos = MousePosition;
		MousePauseTime = 0.f;
	}
	else if( !bMouseWasIdle && (MousePauseTime+=DeltaTime)>0.5f )
	{
		bMouseWasIdle = true;
		if( MouseFocus!=None )
			MouseFocus.NotifyMousePaused();
	}

	if( ActiveMenus.Length>0 )
		MenuTime+=DeltaTime;
		
	V = ClientViewport.GetMousePosition();
	
	MousePosition.X = Clamp(V.X, 0, ScreenSize.X);
	MousePosition.Y = Clamp(V.Y, 0, ScreenSize.Y);
	
	MouseMove();
}

simulated function MouseMove()
{
	local int i;
	local KFGUI_Base F;

	// Capture mouse for GUI
	if( InputFocus!=None && InputFocus.bCanFocus )
	{
		if( InputFocus.CaptureMouse() )
		{
			F = InputFocus.GetMouseFocus();
			if( F!=MouseFocus )
			{
				MousePauseTime = 0;
				if( MouseFocus!=None )
					MouseFocus.MouseLeave();
				MouseFocus = F;
				F.MouseEnter();
			}
		}
		else i = ActiveMenus.Length;
	}
	else
	{
		for( i=0; i<ActiveMenus.Length; ++i )
		{
			if( ActiveMenus[i].CaptureMouse() )
			{
				F = ActiveMenus[i].GetMouseFocus();
				if( F!=MouseFocus )
				{
					MousePauseTime = 0;
					if( MouseFocus!=None )
						MouseFocus.MouseLeave();
					MouseFocus = F;
					F.MouseEnter();
				}
				break;
			}
			else if( ActiveMenus[i].bOnlyThisFocus ) // Discard any other menus after this one.
			{
				i = ActiveMenus.Length;
				break;
			}
		}
	}
	if( MouseFocus!=None && i==ActiveMenus.Length ) // Hovering over nothing.
	{
		MousePauseTime = 0;
		if( MouseFocus!=None )
			MouseFocus.MouseLeave();
		MouseFocus = None;
	}
}

simulated final function int GetFreeIndex( bool bNewAlwaysTop ) // Find first allowed top index of the stack.
{
	local int i;
	
	for( i=0; i<ActiveMenus.Length; ++i )
		if( bNewAlwaysTop || !ActiveMenus[i].bAlwaysTop )
		{
			ActiveMenus.Insert(i,1);
			return i;
		}
	i = ActiveMenus.Length;
	ActiveMenus.Length = i+1;
	return i;
}

simulated function KFGUI_Page OpenMenu( class<KFGUI_Page> MenuClass )
{
	local int i;
	local KFGUI_Page M;
	
	if( MenuClass==None )
		return None;

	if( KeyboardFocus!=None )
		GrabInputFocus(None);
	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}

	// Enable mouse on UI if disabled.
	SetMenuState(true);
	
	// Check if should use pre-existing menu.
	if( MenuClass.Default.bUnique )
	{
		for( i=0; i<ActiveMenus.Length; ++i )
			if( ActiveMenus[i].Class==MenuClass )
			{
				if( i>0 && ActiveMenus[i].BringPageToFront() ) // Sort it upfront.
				{
					M = ActiveMenus[i];
					ActiveMenus.Remove(i,1);
					i = GetFreeIndex(M.bAlwaysTop);
					ActiveMenus[i] = M;
				}
				return M;
			}
		
		if( MenuClass.Default.bPersistant )
		{
			for( i=0; i<PersistentMenus.Length; ++i )
				if( PersistentMenus[i].Class==MenuClass )
				{
					M = PersistentMenus[i];
					PersistentMenus.Remove(i,1);
					i = GetFreeIndex(M.bAlwaysTop);
					ActiveMenus[i] = M;
					M.ShowMenu();
					return M;
				}
		}
	}
	M = New(None)MenuClass;

	if( M==None ) // Probably abstract class.
		return None;
	
	i = GetFreeIndex(M.bAlwaysTop);
	ActiveMenus[i] = M;
	M.Owner = Self;
	M.InitMenu();
	M.ShowMenu();
	return M;
}
simulated function CloseMenu( class<KFGUI_Page> MenuClass, optional bool bCloseAll )
{
	local int i, j;
	local KFGUI_Page M;

	if( !bCloseAll && MenuClass==None )
		return;
	
	if( KeyboardFocus!=None )
		GrabInputFocus(None);
	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}
	for( i=(ActiveMenus.Length-1); i>=0; --i )
	{
		if( bCloseAll || ActiveMenus[i].Class==MenuClass )
		{
			M = ActiveMenus[i];
			ActiveMenus.Remove(i,1);
			M.CloseMenu();
			
			for( j=0; j<M.TimerNames.Length; j++ )
			{
				M.ClearTimer(M.TimerNames[j]);
			}
			
			// Cache menu.
			if( M.bPersistant && M.bUnique )
				PersistentMenus[PersistentMenus.Length] = M;
		}
	}
	if( ActiveMenus.Length==0 )
	{
		SetMenuState(false);
	}
}
simulated function PopCloseMenu( KFGUI_Base Item )
{
	local int i;
	local KFGUI_Page M;

	if( Item==None )
		return;
	
	if( KeyboardFocus!=None )
		GrabInputFocus(None);
	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}
	for( i=(ActiveMenus.Length-1); i>=0; --i )
		if( ActiveMenus[i]==Item )
		{
			M = ActiveMenus[i];
			ActiveMenus.Remove(i,1);
			M.CloseMenu();
			
			// Cache menu.
			if( M.bPersistant && M.bUnique )
				PersistentMenus[PersistentMenus.Length] = M;
			break;
		}
	if( ActiveMenus.Length==0 )
		SetMenuState(false);
}
simulated function BringMenuToFront( KFGUI_Page Page )
{
	local int i;
	
	if( ActiveMenus[0].bAlwaysTop && !Page.bAlwaysTop )
		return; // Can't override this menu.

	// Try to remove from current position at stack.
	for( i=(ActiveMenus.Length-1); i>=0; --i )
		if( ActiveMenus[i]==Page )
		{
			ActiveMenus.Remove(i,1);
			break;
		}
	if( i==-1 )
		return; // Page isn't open.
	
	// Put on front of stack.
	ActiveMenus.Insert(0,1);
	ActiveMenus[0] = Page;
}
simulated final function bool MenuIsOpen( optional class<KFGUI_Page> MenuClass )
{
	local int i;
	
	for( i=(ActiveMenus.Length-1); i>=0; --i )
		if( MenuClass==None || ActiveMenus[i].Class==MenuClass )
			return true;
	return false;
}
simulated final function GrabInputFocus( KFGUI_Base Comp, optional bool bForce )
{
	if( Comp==KeyboardFocus && !bForce )
		return;

	if( KeyboardFocus!=None )
		KeyboardFocus.LostKeyFocus();

	if( Comp==None )
	{
		OnInputKey = InternalInputKey;
		OnReceivedInputChar = InternalReceivedInputChar;
	}
	else if( KeyboardFocus==None )
	{
		OnInputKey = Comp.NotifyInputKey;
		OnReceivedInputChar = Comp.NotifyInputChar;
		OnReceivedInputAxis = Comp.NotifyInputAxis;
	}
	KeyboardFocus = Comp;
}

simulated final function GUI_InputMouse( bool bPressed, bool bRight )
{
	local byte i;

	MousePauseTime = 0;
	
	if( bPressed )
	{
		if( KeyboardFocus!=None && KeyboardFocus!=MouseFocus )
		{
			GrabInputFocus(None);
			LastClickTimes[0] = 0;
			LastClickTimes[1] = 0;
		}
		if( MouseFocus!=None )
		{
			if( MouseFocus!=InputFocus && !MouseFocus.bClickable && !MouseFocus.IsTopMenu() && MouseFocus.BringPageToFront() )
			{
				BringMenuToFront(MouseFocus.GetPageTop());
				LastClickTimes[0] = 0;
				LastClickTimes[1] = 0;
			}
			else
			{
				i = byte(bRight);
				if( (MenuTime-LastClickTimes[i])<0.2 && Abs(LastClickPos[i].X-MousePosition.X)<5 && Abs(LastClickPos[i].Y-MousePosition.Y)<5 )
				{
					LastClickTimes[i] = 0;
					MouseFocus.DoubleMouseClick(bRight);
				}
				else
				{
					MouseFocus.MouseClick(bRight);
					LastClickTimes[i] = MenuTime;
					LastClickPos[i] = MousePosition;
				}
			}
		}
		else if( InputFocus!=None )
		{
			InputFocus.LostInputFocus();
			InputFocus = None;
			LastClickTimes[0] = 0;
			LastClickTimes[1] = 0;
		}
	}
	else
	{
		if( InputFocus!=None )
			InputFocus.MouseRelease(bRight);
		else if( MouseFocus!=None )
			MouseFocus.MouseRelease(bRight);
	}
}
simulated final function bool CheckMouse( name Key, EInputEvent Event )
{
	if ( Event == IE_Pressed )
	{
		switch( Key )
		{
		case 'XboxTypeS_A':
		case 'LeftMouseButton':
			GUI_InputMouse(true,false);
			return true;
		case 'XboxTypeS_B':
		case 'RightMouseButton':
			GUI_InputMouse(true,true);
			return true;
		}
	}
	else if ( Event == IE_Released )
	{
		switch( Key )
		{
		case 'XboxTypeS_A':
		case 'LeftMouseButton':
			GUI_InputMouse(false,false);
			return true;
		case 'XboxTypeS_B':
		case 'RightMouseButton':
			GUI_InputMouse(false,true);
			return true;
		}
	}
	return false;
}
simulated function bool ReceivedInputKey( int ControllerId, name Key, EInputEvent Event, optional float AmountDepressed=1.f, optional bool bGamepad )
{
	local KFPlayerInput KFInput;
	local KeyBind BoundKey;
	
	if( !bIsInMenuState )
		return false;
		
	bUsingGamepad = bGamepad;
		
	KFInput = KFPlayerInput(BackupInput);
	if( KFInput == None )
	{
		KFInput = KFPlayerInput(PlayerOwner.PlayerInput);
	}
		
	if( KeyboardFocus == None )
	{
		if( KFInput != None )
		{    
			KFInput.GetKeyBindFromCommand(BoundKey, "GBA_VoiceChat", false);    
			if( string(Key) ~= KFInput.GetBindDisplayName(BoundKey) )
			{
				if( Event == IE_Pressed )
				{
					KFInput.StartVoiceChat(true);
				}
				else if( Event == IE_Released )
				{
					KFInput.StopVoiceChat();
				}
				
				return true;
			}
		}
	}

	if( !CheckMouse(Key,Event) && !OnInputKey(ControllerId,Key,Event,AmountDepressed,bGamepad) )
	{
		if( bGamepad )
		{
			if( ActiveMenus[0].ReceievedControllerInput(ControllerId, Key, Event) )
				return true;
		}
	
		switch( Key )
		{
		case 'XboxTypeS_Start':
		case 'Escape':
			if( Event==IE_Pressed )
				ActiveMenus[0].UserPressedEsc(); // Pop top menu if possible. // IE_Released
			return true;
		case 'XboxTypeS_DPad_Up':
		case 'XboxTypeS_DPad_Down':
		case 'XboxTypeS_DPad_Left':
		case 'XboxTypeS_DPad_Right':
		case 'MouseScrollDown':
		case 'MouseScrollUp':
			if( Event==IE_Pressed && MouseFocus!=None )
				MouseFocus.ScrollMouseWheel(Key=='MouseScrollUp' || Key=='XboxTypeS_DPad_Up' || Key=='XboxTypeS_DPad_Left');
			return true;
		}
		
		return bAbsorbInput;
	}
	
	return true;
}
simulated function bool ReceivedInputAxis( int ControllerId, name Key, float Delta, float DeltaTime, bool bGamepad )
{
	local Vector2D V;
	local KFPlayerInput KFInput;
	local float GamepadSensitivity,OldMouseX,OldMouseY,MoveDelta,MoveDeltaInvert;
	
	if( !bIsInMenuState )
		return false;
	
	if( bGamepad  )
	{
		if( Abs(Delta) > 0.2f )
		{
			bUsingGamepad = true;
			
			V = ClientViewport.GetMousePosition();
			OldMouseX = V.X;
			OldMouseY = V.Y;
			
			KFInput = KFPlayerInput(BackupInput);
			GamepadSensitivity = KFInput.GamepadSensitivityScale * 10;
			MoveDelta = Delta * (KFInput.bInvertController ? -GamepadSensitivity : GamepadSensitivity);
			MoveDeltaInvert = Delta * (KFInput.bInvertController ? GamepadSensitivity : -GamepadSensitivity);
			
			switch(Key)
			{
				case 'XboxTypeS_LeftX':
				case 'XboxTypeS_RightX':
					if( Delta < 0 )
						V.X = Clamp(V.X - MoveDeltaInvert, 0, ScreenSize.X);
					else V.X = Clamp(V.X + MoveDelta, 0, ScreenSize.X);
					break;
				case 'XboxTypeS_LeftY':
					if( Delta < 0 )
						V.Y = Clamp(V.Y + MoveDeltaInvert, 0, ScreenSize.Y);
					else V.Y = Clamp(V.Y - MoveDelta, 0, ScreenSize.Y);
					break;
				case 'XboxTypeS_RightY':
					if( Delta < 0 )
						V.Y = Clamp(V.Y - MoveDeltaInvert, 0, ScreenSize.Y);
					else V.Y = Clamp(V.Y + MoveDelta, 0, ScreenSize.Y);
					break;
			}
			
			if( OldMouseX != V.X || OldMouseY != V.Y )
				ClientViewport.SetMouse(V.X, V.Y);
		}
	}
	return OnReceivedInputAxis(ControllerId, Key, Delta, DeltaTime, bGamepad);
}
simulated function bool ReceivedInputChar( int ControllerId, string Unicode )
{
	if( !bIsInMenuState )
		return false;
	return OnReceivedInputChar(ControllerId,Unicode);
}

simulated Delegate bool OnInputKey( int ControllerId, name Key, EInputEvent Event, optional float AmountDepressed=1.f, optional bool bGamepad )
{
	return false;
}
simulated Delegate bool OnReceivedInputAxis( int ControllerId, name Key, float Delta, float DeltaTime, bool bGamepad )
{
	return false;
}
simulated Delegate bool OnReceivedInputChar( int ControllerId, string Unicode )
{
	return false;
}
simulated Delegate bool InternalInputKey( int ControllerId, name Key, EInputEvent Event, optional float AmountDepressed=1.f, optional bool bGamepad )
{
	return false;
}
simulated Delegate bool InternalReceivedInputChar( int ControllerId, string Unicode )
{
	return false;
}

defaultproperties
{
	RepObject=ObjectReferencer'menu.RefObject.MenuRefList'
	RepIcons=ObjectReferencer'menu.RefObject.IconRefList'
	
	DefaultStyle=class'ST_GUIStyle'
	bAbsorbInput=true
	bAlwaysTick=true
}