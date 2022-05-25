Class ST_GUIStyle extends KFGUI_StyleBase;

const TOOLTIP_BORDER=4;

function RenderWrenchInfo()
{
	/*
	local float X, Y, XL, YL, FontScale;
	local byte i;
	local KeyBind BoundKey;

	//Setup
	Canvas.Font = PickFont(FontScale);
	X = Canvas.ClipX * 0.99; // change to canvas.SizeX - amount
	Y = Canvas.ClipY * 0.1;

	// Calc text line Max dimensions
	Canvas.TextSize(ModeInfos[2], XL, YL, FontScale, FontScale);

	// Draw transparent background
	Canvas.SetDrawColor(255,255,255,255);
	DrawTileStretched();

	Canvas.SetDrawColor(236,227,203,255);
	
	// TODO: Get refund percentage from reference object and add it to refund string
	// TODO: Use KFInput.GetKeyBindFromCommand(BoundKey, default.USE_COMMAND, false); etc to build strings
	// TODO: Add a backer texture (small border), maybe semi-transparent
	Canvas.TextSize(ModeInfos[2], XL, YL, FontScale, FontScale);
	for(i = 0; i < ModeInfos.Length; ++i)
	{
		Canvas.SetPos(X - XL, Y);
		Canvas.DrawText(ModeInfos[i], , FontScale, FontScale);
		Y += YL;
	}
	*/
	
	/*simulated final function RefreshOverlayValues()
	{
		ModeInfos[2] = Default.ModeInfos[2]$CurrentTurretType.Default.BuildCost@Chr(163)$")";
		ModeInfos[3] = Default.ModeInfos[3]$Int(RefundMultiplier * 100)$Chr(37)$" refund)";
	}
	ModeInfos(0) = "Sentry Hammer Controls:"
	ModeInfos(1) = "[Fire]  Repair"
	ModeInfos(2) = "[Hold AltFire]  Build (Cost: "
	ModeInfos(3) = "[AltFire]  Sell ("
	AdminInfo = "Use Admin SentryHelp for commands"
	
	*/
}

function RenderWeaponTile(Canvas C)
{
	local float FontScale;

	C.Font = PickFont(FontScale, FONT_NAME);
	C.SetDrawColor(255, 255, 255, 255);
	C.SetPos(0, 0);

	C.DrawText("Hovering Text",, FontScale, FontScale);
}

function RenderWindowShadow(float WPos[4])
{
	local int TexSize;

	TexSize = WinHighlight.GetSurfaceWidth();

	WPos[0] -= TexSize / 2;
	WPos[1] -= TexSize / 2;
	WPos[2] += TexSize;
	WPos[3] += TexSize;

    //Canvas.SetOrigin(WPos[0], WPos[1]);
    //Canvas.SetClip(WPos[0] + WPos[2], WPos[1] + WPos[3]);
    Canvas.SetOrigin(WPos[0], WPos[1]);
    Canvas.SetClip(WPos[0] + WPos[2], WPos[1] + WPos[3]);
	DrawTileStretched(WinHighlight, 0, 0, WPos[2], WPos[3]);
}

function RenderFramedWindow( KFGUI_FloatingWindow P )
{
	local int XS, YS, TitleHeight;
	local float XL, YL, FontScale;
	
	
	TitleHeight = DefaultHeight;

	Canvas.SetDrawColor(255,255,255,255);

	XS = Canvas.ClipX-Canvas.OrgX;
	YS = Canvas.ClipY-Canvas.OrgY;
	
	// Frame itself
	DrawTileStretched(BorderTextures[`BOX_SMALL], 0, 0, XS, YS);
	
	// Title
	if(P.WindowTitle != "")
	{
		Canvas.Font = PickFont(FontScale, FONT_NAME);
		Canvas.TextSize(P.WindowTitle,XL,YL,FontScale,FontScale);
		Canvas.SetDrawColor(236,227,203,255); // TODO: use P.TextColor
		Canvas.SetPos((XS - XL) / 2.0f, (TitleHeight - YL) / 2.0f);
		Canvas.DrawText(P.WindowTitle,,FontScale,FontScale);
	}
}

function RenderWindow( KFGUI_Page P )
{
	local int XS,YS;
	
	XS = Canvas.ClipX-Canvas.OrgX;
	YS = Canvas.ClipY-Canvas.OrgY;

	// Frame itself
	Canvas.SetDrawColor(255,255,255,255);
	
	DrawTileStretched(BorderTextures[`BOX_SMALL], 0, 0, XS, YS);
}

function RenderToolTip( KFGUI_Tooltip TT )
{
	local int i;
	local float X,Y,XS,YS,TX,TY,TS,DefFontHeight;

	Canvas.Font = PickFont(TS);

	// First compute textbox size.
	TY = DefaultHeight*TT.Lines.Length;
	for( i=0; i<TT.Lines.Length; ++i )
	{
		if( TT.Lines[i]!="" )
			Canvas.TextSize(TT.Lines[i],XS,YS);
		TX = FMax(XS,TX);
	}
	TX*=TS;
	
	// Give some borders.
	TX += TOOLTIP_BORDER*2;
	TY += TOOLTIP_BORDER*2;

	X = TT.CompPos[0];
	Y = TT.CompPos[1]+24.f;

	// Then check if too close to window edge, then move it to another pivot.
	if( (X+TX)>TT.Owner.ScreenSize.X )
		X = TT.Owner.ScreenSize.X-TX;
	if( (Y+TY)>TT.Owner.ScreenSize.Y )
		Y = TT.CompPos[1]-TY;
	
	if( TT.CurrentAlpha<255 )
		TT.CurrentAlpha = Min(TT.CurrentAlpha+25,255);

	// Reset clipping.
	Canvas.SetOrigin(0,0);
	Canvas.SetClip(TT.Owner.ScreenSize.X,TT.Owner.ScreenSize.Y);

	// Draw frame.
	Canvas.SetDrawColor(115,115,115,TT.CurrentAlpha);
	Canvas.SetPos(X-2,Y-2);
	DrawBoxHollow(X-2,Y-2,TX+4,TY+4,2);
	Canvas.SetDrawColor(5,5,5,TT.CurrentAlpha);
	Canvas.SetPos(X,Y);
	DrawWhiteBox(TX,TY);
	
	DefFontHeight = DefaultHeight;

	// Draw text.
	Canvas.SetDrawColor(236,227,203,TT.CurrentAlpha);
	X+=TOOLTIP_BORDER;
	Y+=TOOLTIP_BORDER;
	for( i=0; i<TT.Lines.Length; ++i )
	{
		Canvas.SetPos(X,Y);
		Canvas.DrawText(TT.Lines[i],,TS,TS,TT.TextFontInfo);
		Y+=DefFontHeight;
	}
}

function RenderScrollBar( KFGUI_ScrollBarBase S )
{
	local float A;
	local byte i;

	Canvas.SetDrawColor(255, 255, 255, 255);

	DrawTileStretched(BorderTextures[`BUTTON_NORMAL], 0, 0, S.CompPos[2], S.CompPos[3]);
	
	if( S.bDisabled )
		return;

	if( S.bVertical )
		i = 3;
	else i = 2;
	
	S.SliderScale = FMax(S.PageStep * (S.CompPos[i] - 32.f) / (S.MaxRange + S.PageStep),S.CalcButtonScale);
	
	if( S.bGrabbedScroller )
	{
		// Track mouse.
		if( S.bVertical )
			A = S.Owner.MousePosition.Y - S.CompPos[1] - S.GrabbedOffset;
		else A = S.Owner.MousePosition.X - S.CompPos[0] - S.GrabbedOffset;
		
		A /= ((S.CompPos[i]-S.SliderScale) / float(S.MaxRange));
		S.SetValue(A);
	}

	A = float(S.CurrentScroll) / float(S.MaxRange);
	S.ButtonOffset = A*(S.CompPos[i]-S.SliderScale);

	if( S.bGrabbedScroller )
		Canvas.SetDrawColor(125,125,125,255);
	else if( S.bFocused )
		Canvas.SetDrawColor(200,200,200,255);
	else Canvas.SetDrawColor(255,255,255,255);

	if( S.bVertical )
	{
		//Canvas.SetPos(0.f, S.ButtonOffset);
		DrawTileStretched(ScrollTexture, 0, S.ButtonOffset, S.CompPos[2], S.SliderScale);
	}
	else 
	{
		//Canvas.SetPos(S.ButtonOffset, 0.f);
		DrawTileStretched(ScrollTexture, S.ButtonOffset, 0, S.SliderScale, S.CompPos[3]);
	}
}

function RenderCheckbox( KFGUI_CheckBox C )
{
	local Texture2D CheckMark;
	
	DrawTileStretched(ItemBoxTextures[`ITEMBOX_DISABLED], 0, 0, C.CompPos[2], C.CompPos[3]);

	if( C.bChecked )
	{
		if( C.bDisabled )
			CheckMark = CheckBoxTextures[`CHECKMARK_DISABLED];
		else if( C.bFocused )
			CheckMark = CheckBoxTextures[`CHECKMARK_HIGHLIGHTED];
		else CheckMark = CheckBoxTextures[`CHECKMARK_NORMAL];
			
		Canvas.SetDrawColor(255,255,255,255);
		Canvas.SetPos(0.f,0.f);
		Canvas.DrawTile(CheckMark,C.CompPos[2],C.CompPos[3],0,0,CheckMark.GetSurfaceWidth(),CheckMark.GetSurfaceHeight());
	}
}

function RenderComboBox( KFGUI_ComboBox C )
{
	if( C.bDisabled )
		Canvas.SetDrawColor(64,64,64,255);
	else if( C.bPressedDown )
		Canvas.SetDrawColor(220,220,220,255);
	else if( C.bFocused )
		Canvas.SetDrawColor(190,190,190,255);
	
	DrawTileStretched(BorderTextures[`BOX_INNERBORDER], 0, 0, C.CompPos[2], C.CompPos[3]);
	
	DrawArrowBox(3, C.CompPos[2]-32, 0.5f, 32, 32);

	if( C.SelectedIndex<C.Values.Length && C.Values[C.SelectedIndex]!="" )
	{
		Canvas.SetPos(C.BorderSize,(C.CompPos[3]-C.TextHeight)*0.5);
		if( C.bDisabled )
			Canvas.DrawColor = C.TextColor*0.5f;
		else Canvas.DrawColor = C.TextColor;
		Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX-C.BorderSize,Canvas.ClipY);
		Canvas.DrawText(C.Values[C.SelectedIndex],,C.TextScale,C.TextScale,C.TextFontInfo);
		Canvas.PopMaskRegion();
	}
}

function RenderComboList( KFGUI_ComboSelector C )
{
	local float X,Y,YL,YP,Edge;
	local int i;
	local bool bCheckMouse;
	
	// Draw background.
	Edge = C.Combo.BorderSize;
	DrawTileStretched(BorderTextures[`BOX_SMALL], 0, 0, C.CompPos[2],C.CompPos[3]);

	// While rendering, figure out mouse focus row.
	X = C.Owner.MousePosition.X - Canvas.OrgX;
	Y = C.Owner.MousePosition.Y - Canvas.OrgY;
	
	bCheckMouse = (X>0.f && X<C.CompPos[2] && Y>0.f && Y<C.CompPos[3]);
	
	Canvas.Font = C.Combo.TextFont;
	YL = C.Combo.TextHeight;

	YP = Edge;
	C.CurrentRow = -1;

	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	for( i=0; i<C.Combo.Values.Length; ++i )
	{
		if( bCheckMouse && Y>=YP && Y<=(YP+YL) )
		{
			bCheckMouse = false;
			C.CurrentRow = i;
			Canvas.SetPos(4.f,YP);
			Canvas.SetDrawColor(128,48,48,255);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f),YL);
		}
		Canvas.SetPos(Edge,YP);
		
		if( i==C.Combo.SelectedIndex )
			Canvas.DrawColor = C.Combo.SelectedTextColor;
		else Canvas.DrawColor = C.Combo.TextColor;

		Canvas.DrawText(C.Combo.Values[i],,C.Combo.TextScale,C.Combo.TextScale,C.Combo.TextFontInfo);
		
		YP+=YL;
	}
	Canvas.PopMaskRegion();
	if( C.OldRow!=C.CurrentRow )
	{
		C.OldRow = C.CurrentRow;
		C.PlayMenuSound(MN_DropdownChange);
	}
}

function RenderRightClickMenu( KFGUI_RightClickMenu C )
{
	local float X,Y,XL,YL,YP,Edge,TextScale;
	local int i;
	local bool bCheckMouse;
	local string S;
	
	// Draw background.
	Edge = C.EdgeSize;
	DrawOutlinedBox(0.f,0.f,C.CompPos[2],C.CompPos[3],Edge,C.BoxColor,C.OutlineColor);

	// While rendering, figure out mouse focus row.
	X = C.Owner.MousePosition.X - Canvas.OrgX;
	Y = C.Owner.MousePosition.Y - Canvas.OrgY;
	
	bCheckMouse = (X>0.f && X<C.CompPos[2] && Y>0.f && Y<C.CompPos[3]);
	
	PickFont(TextScale);

	YP = Edge*2;
	C.CurrentRow = -1;
	
	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	for( i=0; i<C.ItemRows.Length; ++i )
	{
		if( C.ItemRows[i].bSplitter )
			S = "-------";
		else S = C.ItemRows[i].Text;
		
		Canvas.TextSize(S,XL,YL,TextScale,TextScale);
		
		if( bCheckMouse && Y>=YP && Y<=(YP+YL) )
		{
			bCheckMouse = false;
			C.CurrentRow = i;
			Canvas.SetPos(Edge,YP);
			Canvas.SetDrawColor(128,0,0,255);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f),YL);
		}

		Canvas.SetPos(Edge*6,YP);
		if( C.ItemRows[i].bSplitter )
			Canvas.SetDrawColor(255,255,255,255);
		else
		{
			if( C.ItemRows[i].bDisabled )
				Canvas.SetDrawColor(148,148,148,255);
			else Canvas.SetDrawColor(248,248,248,255);
		}
		Canvas.DrawText(S,,TextScale,TextScale);
		
		YP+=YL;
	}
	Canvas.PopMaskRegion();
	if( C.OldRow!=C.CurrentRow )
	{
		C.OldRow = C.CurrentRow;
		C.PlayMenuSound(MN_FocusHover);
	}
}

function RenderButton( KFGUI_Button B )
{
	local float XL, YL, TS, TempScaler, GamepadTexSize;
	local Texture2D Mat, ButtonTex;
	local bool bDrawOverride;

	bDrawOverride = B.DrawOverride(Canvas, B);
	if( !bDrawOverride )
	{
		if( B.bDisabled )
			Mat = ButtonTextures[`BUTTON_DISABLED];
		else if( B.bPressedDown )
			Mat = ButtonTextures[`BUTTON_PRESSED];
		else if( B.bFocused || B.bIsHighlighted )
			Mat = ButtonTextures[`BUTTON_HIGHLIGHTED];
		else Mat = ButtonTextures[`BUTTON_NORMAL];
		
		DrawTileStretched(Mat, 0, 0, B.CompPos[2],B.CompPos[3]);

		if( B.OverlayTexture.Texture!=None )
		{
			Canvas.SetPos(0.f,0.f);
			Canvas.DrawTile(B.OverlayTexture.Texture,B.CompPos[2],B.CompPos[3],B.OverlayTexture.U,B.OverlayTexture.V,B.OverlayTexture.UL,B.OverlayTexture.VL);
		}
	}
	
	if( B.ButtonText!="" )
	{
		Canvas.Font = NameFont;
		
		GamepadTexSize = B.CompPos[3] / 1.25;
		
		TS = GetFontScaler();
		TS *= B.FontScale;

		Canvas.TextSize(B.ButtonText,XL,YL,TS,TS);
		TempScaler = XL / (B.CompPos[2] * 0.9f);
		if( TempScaler > 1.0f )
		{
			TS /= TempScaler;
			Canvas.TextSize(B.ButtonText,XL,YL,TS,TS);
		}

		TempScaler = YL / (B.CompPos[3] * 0.9f);
		if( TempScaler > 1.0f )
		{
			TS /= TempScaler;
			Canvas.TextSize(B.ButtonText,XL,YL,TS,TS);
		}
		
		Canvas.SetPos((B.CompPos[2]-XL)*0.5,(B.CompPos[3]-YL)*0.5);
		if( B.bDisabled )
			Canvas.DrawColor = B.TextColor*0.5f;
		else Canvas.DrawColor = B.TextColor;
		Canvas.DrawText(B.ButtonText,,TS,TS,B.TextFontInfo);
	}
}

function RenderColumnHeader( KFGUI_ColumnTop C, float XPos, float Width, int Index, bool bFocus, bool bSort )
{
	local int XS;

	if( bSort )
	{
		if( bFocus )
			Canvas.SetDrawColor(175,240,8,255);
		else Canvas.SetDrawColor(128,200,56,255);
	}
	else if( bFocus )
		Canvas.SetDrawColor(220,220,8,255);
	else Canvas.SetDrawColor(220,86,56,255);

	XS = DefaultHeight*0.125;
	Canvas.SetPos(XPos,0.f);
	DrawCornerTexNU(XS,C.CompPos[3],0);
	Canvas.SetPos(XPos+XS,0.f);
	DrawWhiteBox(Width-(XS*2),C.CompPos[3]);
	Canvas.SetPos(XPos+Width-(XS*2),0.f);
	DrawCornerTexNU(XS,C.CompPos[3],1);
	
	Canvas.SetDrawColor(236,227,203,255);
	Canvas.SetPos(XPos+XS,(C.CompPos[3]-C.ListOwner.TextHeight)*0.5f);
	C.ListOwner.DrawStrClipped(C.ListOwner.Columns[Index].Text);
}

defaultproperties
{
	MaxFontScale=5
}