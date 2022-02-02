// Colidable actor spawned around turrets to enable using the turret's menu

Class SentryTrigger extends Actor
	transient
	implements(KFInterface_Usable);

var ST_Base TurretOwner;
var class<KFGUI_Page> TMenu;
//var UIP_TurretUpgrades TMenu;

simulated function PostBeginPlay()
{
	//TMenu.InitMenu();
}

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	//Server - update hud message if colliding actor is a player
	if(WorldInfo.NetMode != NM_Client && KFPawn_Human(Other) != None)
	{
		class'KFPlayerController'.static.UpdateInteractionMessages(Other);
	}
}
simulated event UnTouch(Actor Other)
{
	//Server - update hud message if colliding actor is a player
	if(WorldInfo.NetMode != NM_Client && KFPawn_Human(Other) != None)
	{
		class'KFPlayerController'.static.UpdateInteractionMessages(Other);
	}
}

function bool UsedBy(Pawn User)
{
	// Server - side logic when User is a player/has a player controller 
	if(WorldInfo.NetMode != NM_DedicatedServer && GetIsUsable(User))
	{
		class'KF2GUIController'.static.GetGUIController(PlayerController(KFPawn_Human(User).Controller)).OpenMenu(TMenu);
		//TMenu.ShowMenu();
	}

	// This is basically the only returned value, perhaps undefined under certain conditions?
	return true;
}

// Limits a turret to be accessed by human players
simulated function bool GetIsUsable(Pawn User)
{
	// If user is a KFPawn_Human return true
	return KFPawn_Human(User) != None;
}

// This returns a KF2 standard 'Press E to Use Objective' hud message
simulated function int GetInteractionIndex(Pawn User)
{
	return IMT_AcceptObjective;
}

defaultproperties
{
	TMenu = class'UI_TurretMenu'

   Begin Object Class=CylinderComponent Name=CollisionCylinder
      CollisionHeight = 56.000000
      CollisionRadius = 56.000000
      ReplacementPrimitive = None
      CollideActors = True
   End Object
   Components(0) = CollisionCylinder
   bHidden = True
   bCollideActors = True
   CollisionComponent = CollisionCylinder
}
