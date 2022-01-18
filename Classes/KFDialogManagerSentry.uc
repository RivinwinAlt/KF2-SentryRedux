//This class allows turrets to find Zeds within their field of view while disabling Zed call-outs
class KFDialogManagerSentry extends KFDialogManager
    config(Game)
    hidecategories(Navigation);

//Wraps the default function such that turrets (which also extend pawn) wont trigger Zed call-outs
function CheckSpotMonsterDialog(Pawn Spotter, KFPawn_Monster Spotted)
{
    if((KFPawn_Human(Spotter) != none) && Spotted != none)
    {
        super.CheckSpotMonsterDialog(Spotter, Spotted);
    }   
}

/*defaultproperties
{
    //Tick will occur after actors are updated
    TickGroup=TG_PostAsyncWork
}*/