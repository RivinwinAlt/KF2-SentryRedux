Class PU_InteractDroppedPickup extends KFDroppedPickup
	implements(KFInterface_Usable);

var Actor LookActor;
var bool bIsLookTarget;
var PU_HoveringWeaponInfo InfoTile;
var vector VOffset;

simulated event SetInitialState()
{
	super.SetInitialState();

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		InfoTile = Spawn(class'PU_HoveringWeaponInfo', Self, , Location + VOffset);
		InfoTile.SetHardAttach(true);
		InfoTile.SetBase(Self);
	}
}

simulated event Landed(Vector HitNormal, Actor FloorActor)
{
	super.Landed(HitNormal, FloorActor);
	
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		InfoTile.SetLocation(Location + VOffset);
	}
}

/** Checks if this actor is presently usable */
simulated function bool GetIsUsable( Pawn User )
{
	local Actor HitA;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;

	// Check for valid setup and conditions
	if(KFPawn_Human(User) == None || MyMeshComp == None || `TimeSince(CreationTime) < PickupDelay)
		return false;

	// Check if User is looking near Pickup
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		if(!bIsLookTarget) // Client Logic
			return false;
	}
	else
	{
		if(!ServerCheckLookTarget(User)) // Server Logic
			return false;
	}

	// Trace from User to Pickup hitbox
	foreach User.TraceActors( class'Actor', HitA, HitLocation, HitNormal, MyCylinderComp.GetPosition() + vect(0,0,10), User.Location, vect(1,1,1), HitInfo )
	{
		if(IsTouchBlockedBy(HitA, HitInfo.HitComponent)) // Helper function defined in KFDroppedPickup.uc
			return false;
	}

	// If no issues found allow interaction
	return true;
}

simulated function bool CheckLookTarget()
{
	if(LookActor == none)
	{
		ClearTimer(nameof(CheckLookTarget));
		bIsLookTarget = false;
		return false;
	}
	
	// If looking away return false
	if((vector(Pawn(LookActor).controller.Rotation) dot Normal(MyMeshComp.Bounds.Origin - LookActor.Location)) < 0.94 ) // The number at the end represents a cone of view.
	{
		// If flag is being flipped update user messages
		if(bIsLookTarget)
		{
			bIsLookTarget = false;
			UpdateMessage();
		}
		return false;
	}

	// If flag is being flipped update user messages
	if(!bIsLookTarget)
	{
		bIsLookTarget = true;
		UpdateMessage();
	}
	return true;
}

//This method ignores more important interactions, rewrite
simulated function UpdateMessage()
{
	local PlayerController PC;

	if(Pawn(LookActor) != none)
		PC = PlayerController( Pawn(LookActor).Controller );
	if(PC == none)
		return;

	if(bIsLookTarget)
	{
		PC.ReceiveLocalizedMessage( class'KFLocalMessage_Interaction', IMT_AcceptObjective );
	}
	else
	{
		PC.ReceiveLocalizedMessage( class'KFLocalMessage_Interaction', IMT_None );
	}
}

function bool ServerCheckLookTarget(Pawn User)
{
	if(User == none)
	{
		`log("ST_DropHelper: Pawn is null in LookCheck function");
		return false;
	}
	
	// If looking away return false
	if((vector(User.controller.Rotation) dot Normal(MyMeshComp.Bounds.Origin - User.Location)) < 0.94 ) // The number at the end represents a cone of view.
	{
		return false;
	}

	return true;
}

/** Return the index for our interaction message. */
simulated function int GetInteractionIndex( Pawn User )
{
	// Shows "Press E to Accept Objective"
	return IMT_None;
	// Alternately this system can be replaced with a canvas drawing system capable of custom messages.
}

function bool UsedBy(Pawn User)
{
	// Make sure User is a live player
	if (User == None || !User.bCanPickupInventory || !User.IsAliveAndWell() || (User.DrivenVehicle == None && User.Controller == None))
	{
		return false;
	}

	// Make sure game will allow pickup
	if(WorldInfo.Game.PickupQuery(User, Inventory.class, self))
	{
		GiveTo(User);
		return true;
	}

	return false;
}

simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal );

simulated event UnTouch( Actor Other );

simulated event Destroyed()
{
	if(LookActor != none)
	{
		bIsLookTarget = false;
		UpdateMessage();
	}

	if(InfoTile != none)
	{
		InfoTile.Destroy();
		InfoTile = none;
	}
	
	if(WorldInfo.Netmode != NM_Client)
	{
		super.Destroyed();

		if(Inventory != None)
		{
			Inventory.Destroy();
			Inventory = None;
		}
	}
}

// Overridden to remove instant pickup logic
auto simulated state Pickup
{
	simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
	{
		LookActor = Other;
		
		if(WorldInfo.NetMode != NM_DedicatedServer)
		{
			InfoTile.bInRange = true;
			SetTimer(0.1, true, nameof(CheckLookTarget));
		}
	}

	simulated event UnTouch( Actor Other )
	{
		ClearTimer(nameof(CheckLookTarget));
		InfoTile.bInRange = false;
		if(bIsLookTarget)
		{
			`log("ST_DropHelper: Untouch(): Player was looking at Pickup, cleaning up");
			bIsLookTarget = false;
			UpdateMessage();
		}
	}
}

defaultproperties
{
	VOffset=(X=0,Y=0,Z=80)

	Begin Object NAME=CollisionCylinder
		CollisionRadius=+00200.000000 // Up from 75
		CollisionHeight=+00040.000000
		CollideActors=true
		Translation=(Z=40) // offset by CollisionHeight so that cylinder is on floor
	End Object	
}