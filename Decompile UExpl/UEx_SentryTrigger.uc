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
		if( SN==None )
		{
			SN = Spawn(class'SentryUI_Network',User);
			SN.PlayerOwner = PlayerController(User.Controller);
			SN.SetTurret(TurretOwner);
		}
	}
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


// Decompiled with UE Explorer.
defaultproperties
{
    begin object name=CollisionCylinder class=CylinderComponent
        CollisionHeight=56.0
        CollisionRadius=56.0
        ReplacementPrimitive=none
        CollideActors=true
    object end
    // Reference: CylinderComponent'Default__SentryTrigger.CollisionCylinder'
    Components(0)=CollisionCylinder
    bHidden=true
    bCollideActors=true
    begin object name=CollisionCylinder class=CylinderComponent
        CollisionHeight=56.0
        CollisionRadius=56.0
        ReplacementPrimitive=none
        CollideActors=true
    object end
    // Reference: CylinderComponent'Default__SentryTrigger.CollisionCylinder'
    CollisionComponent=CollisionCylinder
}