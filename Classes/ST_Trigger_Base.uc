Class ST_Trigger_Base extends Actor
	transient
	implements(KFInterface_Usable);

var ST_Turret_Base TurretOwner;

replication
{
	// Variables the server should send ALL clients.
	if(bNetDirty)
		TurretOwner;
}

simulated event ReplicatedEvent(name VarName)
{
	switch(VarName)
	{
	case 'TurretOwner':
		if(TurretOwner != none)
		{
			TurretOwner.ActiveTrigger = Self;
			SetBase(TurretOwner);
		}
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	if( WorldInfo.NetMode!=NM_Client && KFPawn_Human(Other)!=None )
		class'KFPlayerController'.static.UpdateInteractionMessages( Other );
}
simulated event UnTouch(Actor Other)
{
	if( WorldInfo.NetMode!=NM_Client && KFPawn_Human(Other)!=None )
		class'KFPlayerController'.static.UpdateInteractionMessages( Other );
}

function bool UsedBy(Pawn User)
{
	local ST_SentryNetwork SN;

	
	if( WorldInfo.NetMode!=NM_Client && PlayerController(User.Controller)!=None )
	{
		SN = class'ST_SentryNetwork'.static.GetNetwork(PlayerController(User.Controller));
		SN.SetInfo(TurretOwner, PlayerController(User.Controller));
	}

	return true;
}

/** Checks if this actor is presently usable */
simulated function bool GetIsUsable( Pawn User )
{
	return KFPawn_Human(User) != None;
}

/** Return the index for our interaction message. */
simulated function int GetInteractionIndex( Pawn User )
{
	//return IMT_AcceptObjective;
	return IMT_None;
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
}
