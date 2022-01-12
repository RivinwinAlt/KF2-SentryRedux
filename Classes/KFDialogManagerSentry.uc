//This class allows turrets to find Zeds within their field of view while disabling Zed call-outs
class KFDialogManagerSentry extends KFDialogManager
    config(Game) //Allows options to be pulled from the main game config file
    hidecategories(Navigation); //Effects Editor

//Wraps the default function such that turrets (which also extend pawn) wont trigger Zed call-outs
function CheckSpotMonsterDialog(Pawn Spotter, KFPawn_Monster Spotted)
{
    if((KFPawn_Human(Spotter) != none) && Spotted != none)
    {
        super.CheckSpotMonsterDialog(Spotter, Spotted);
    }
}

defaultproperties
{
    //Tick will occur after actors are updated
    TickGroup=TG_PostAsyncWork
    
    //Add a copy of the default message managers dataset
    Name="Default__KFDialogManagerSentry"
    ObjectArchetype=KFDialogManager'KFGame.Default__KFDialogManager'
}
