// Colidable actor spawned around turrets to enable using the turret's menu

Class SentryTrigger extends Actor
	transient
	implements(KFInterface_Usable);

var SentryTurret TurretOwner;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	//Server-side logic
	if( WorldInfo.NetMode!=NM_Client )
		class'KFPlayerController'.static.UpdateInteractionMessages( Other );
}
simulated event UnTouch(Actor Other)
{
	local SentryUI_Network SN;

	//Server-side logic if colliding actor is a Pawn
	//Changed Pawn() to KFPawn_Human() to avoid unecesary updates
	if( WorldInfo.NetMode!=NM_Client && KFPawn_Human(Other)!=None )
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

	// Server-side logic when User is a player/has a player controller 
	if( WorldInfo.NetMode!=NM_Client && PlayerController(User.Controller)!=None )
	{
		// If the user already has a SentryUI_Network object asign it to SN and dont spawn another
		foreach User.ChildActors(class'SentryUI_Network',SN)
			break;
		if( SN==None )
		{
			// If no object exists spawn a new one
			SN = Spawn(class'SentryUI_Network',User);
			SN.PlayerOwner = PlayerController(User.Controller);
			SN.SetTurret(TurretOwner);
		}
	}

	// This is basically the only returned value, perhaps undefined under certain conditions?
	return true;
}

// Limits a turret to be accessed by human players
simulated function bool GetIsUsable( Pawn User )
{
	// If user is a KFPawn_Human return true
	return KFPawn_Human(User)!=None;
}

// This returns a KF2 standard 'Press E to Use Objective' hud message
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
   End Object
   Components(0)=CollisionCylinder
   bHidden=True
   bCollideActors=True
   CollisionComponent=CollisionCylinder
}
