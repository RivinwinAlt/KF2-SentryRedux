Class SentryTrigger extends Actor
	transient
	implements(KFInterface_Usable);

var SentryTurret TurretOwner;

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
		class'KFPlayerController'.static.UpdateInteractionMessages( Other );

		foreach Other.ChildActors(class'SentryUI_Network',SN)
		{
			if( SN.TurretOwner==TurretOwner )
				SN.Destroy();
			break;
		}
	}
}

function bool UsedBy(Pawn User)
{
	local SentryUI_Network SN;

	if( WorldInfo.NetMode!=NM_Client && PlayerController(User.Controller)!=None )
	{
		foreach User.ChildActors(class'SentryUI_Network',SN)
			break;
		//This is the functionality that allows players to get more than one turret?
		if( SN==None )
		{
			SN = Spawn(class'SentryUI_Network',User);
			SN.PlayerOwner = PlayerController(User.Controller);
			SN.SetTurret(TurretOwner);
		}
	}
	return true;
}

//limits a turret to be accessed by one player at a time
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
   Name="Default__SentryTrigger"
   ObjectArchetype=Actor'Engine.Default__Actor'
}
