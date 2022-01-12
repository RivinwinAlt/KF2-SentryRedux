//This is a colidable actor spawned around turrets to enable using the turret's menu.
Class SentryTrigger extends Actor
	transient
	implements(KFInterface_Usable); //Allows putting up the [E to use] overlay

var SentryTurret TurretOwner;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	if( WorldInfo.NetMode!=NM_Client )
		//Server-side logic on touch
		class'KFPlayerController'.static.UpdateInteractionMessages( Other );
}
simulated event UnTouch(Actor Other)
{
	local SentryUI_Network SN;

	//Server-side logic if colliding actor is a Pawn
	//TODO This code would probably execute less if it cast to KFPawn_Human
	if( WorldInfo.NetMode!=NM_Client && Pawn(Other)!=None )
	{
		class'KFPlayerController'.static.UpdateInteractionMessages( Other );

		//Destroy SentryUI_Network objects owned by the turret in question
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

	//Server-side logic when User is a player/has a player controller 
	if( WorldInfo.NetMode!=NM_Client && PlayerController(User.Controller)!=None )
	{
		//If the user already has a UI_Network object asign it to SN and dont spawn another
		foreach User.ChildActors(class'SentryUI_Network',SN)
			break;
		//Unnecesary logic based on above? Have to nail down "break" behavior in foreach loop
		if( SN==None )
		{
			//If no UI_Network object exists spawn a new one
			SN = Spawn(class'SentryUI_Network',User);
			SN.PlayerOwner = PlayerController(User.Controller);
			//WTF is this? It feels like this is how you can steel turrets before they despawn
			SN.SetTurret(TurretOwner);
		}
	}

	//This is basically the only returned value, perhaps undefined under certain conditions?
	return true;
}

//limits a turret to be accessed by human players
simulated function bool GetIsUsable( Pawn User )
{
	//if user is a KFPawn_Human return true
	return KFPawn_Human(User)!=None;
}

/** Return the index for our interaction message. */
//This returns a KF2 standard 'Use' message
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
