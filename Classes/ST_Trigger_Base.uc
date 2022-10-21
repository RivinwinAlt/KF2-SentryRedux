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

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local ST_SentryNetwork SN;

	SetTimer(0.5);
	if(ROLE == ROLE_Authority && KFPawn_Human(Other) != None)
	{
		SN = class'ST_SentryNetwork'.static.GetNetwork(PlayerController(Pawn(Other).Controller));
		SN.UpdateTurretMessage();
	}	
}

event UnTouch(Actor Other)
{
	local ST_SentryNetwork SN;

	if(ROLE == ROLE_Authority && KFPawn_Human(Other) != None)
	{
		SN = class'ST_SentryNetwork'.static.GetNetwork(PlayerController(Pawn(Other).Controller));

		SN.UpdateTurretMessage();
		if(SN.TurretOwner == TurretOwner)
			SN.ClientCloseMenu();
	}
}

function bool UsedBy(Pawn User)
{
	local ST_SentryNetwork SN;

	
	if(WorldInfo.NetMode != NM_Client && PlayerController(User.Controller) != None)
	{
		SN = class'ST_SentryNetwork'.static.GetNetwork(PlayerController(User.Controller));
		SN.SetInfo(TurretOwner, PlayerController(User.Controller));
		SN.UpdateTurretMessage(false);
		SN.ClientOpenMenu(TurretOwner);
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
	// Causes the default handler to not show a message, shown using custom function below
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
