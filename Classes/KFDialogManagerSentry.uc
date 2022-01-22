// Allows disabling zed callouts when turret finds a target

class KFDialogManagerSentry extends KFDialogManager
    config(Game) // This probably isnt necessary here but it doesnt hurt, used in the parent class
    hidecategories(Navigation); // Only relavent to the sdk

// Wraps the default function such that turrets wont trigger Zed call-outs
function CheckSpotMonsterDialog(Pawn Spotter, KFPawn_Monster Spotted)
{
    if((KFPawn_Human(Spotter) != none) && Spotted != none) // Limits callouts to _Human, probably doesnt need to check Spotted
    {
        super.CheckSpotMonsterDialog(Spotter, Spotted);
    }   
}

/*defaultproperties
{
    //Tick will occur after actors are updated
    TickGroup=TG_PostAsyncWork
}*/