Class SentryTrigger extends Actor
	transient
	implements(KFInterface_Usable);

var ST_Base TurretOwner;
var class<KFGUI_Page> ActiveMenu;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	if( WorldInfo.NetMode!=NM_Client )
		class'KFPlayerController'.static.UpdateInteractionMessages( Other );
}
simulated event UnTouch(Actor Other)
{
	local SentryUI_Network SN;
	
	if( WorldInfo.NetMode!=NM_Client && Pawn(Other)!=None )
	{
		class'KFPlayerController'.static.UpdateInteractionMessages(Other);
		foreach Other.ChildActors(class'SentryUI_Network',SN)
		{
			if( SN.TurretOwner==TurretOwner )
				SN.CloseMenuForClient(PlayerController(Pawn(Other).Controller), none, true);
			break;
		}
	}
}

simulated function bool UsedBy(Pawn User)
{
	local SentryUI_Network SN;

	SN = class'SentryUI_Network'.static.GetNetwork(PlayerController(User.Controller));
	SN.PlayerOwner = PlayerController(User.Controller);
	SN.SetTurret(TurretOwner);
	SN.ClientOpenMenu(ActiveMenu);
	
	return true;
}

/** Checks if this actor is presently usable */
simulated function bool GetIsUsable( Pawn User )
{
	return KFPawn_Human(User)!=None;
}

/** Return the index for our interaction message. */
simulated function int GetInteractionIndex( Pawn User )
{
	return IMT_AcceptObjective;
}

defaultproperties
{
	ActiveMenu=class'UI_SentryMenu'
	
   Begin Object Class=CylinderComponent Name=CollisionCylinder
      CollisionHeight=56.000000
      CollisionRadius=56.000000
      ReplacementPrimitive=None
      CollideActors=True
      Name="CollisionCylinder"
      ObjectArchetype=CylinderComponent'Engine.Default__CylinderComponent'
   End Object
   Components(0)=CollisionCylinder
   bHidden=True
   bCollideActors=True
   CollisionComponent=CollisionCylinder
}
