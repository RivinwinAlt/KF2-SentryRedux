class SimpleBot Extends GameAIController;

/** Temp Destination for navmesh destination */
var()  Vector  TempDest;
var bool  GotToDest;
var   Vector  NavigationDestination;

/****************************************************************
*Send your destination to this function
****************************************
*Go to a destination position
*First try navmesh if faild try path nod
****************************************************************/
function GoWithPath(Vector Dest)
{
     NavigationDestination=Dest;
     if( FindNavMeshPath() )
     {

        Pushstate('NavMeshSeeking');
        return;

     }
     else//NavMesh faild try to use Path node 
     {

      SetDestinationPosition (Dest);
      ScriptedMoveTarget = FindPathTo(GetDestinationPosition());
      if(ScriptedMoveTarget != none)
      {
        PushState('ScriptedMove');
        return;
      }
     }
    // Path Finding fail!!!Try Somthing Else
 }
 
/**********************
*Copy past From http://x9productions.com/blog/?page_id=689
***********************/
function bool FindNavMeshPath()
{
  // Clear cache and constraints (ignore recycling for the moment)
  NavigationHandle.PathConstraintList = none;
  NavigationHandle.PathGoalList = none;
  // Create constraints
  class'NavMeshPath_Toward'.static.TowardPoint( NavigationHandle, NavigationDestination );
  class'NavMeshGoal_At'.static.AtLocation( NavigationHandle, NavigationDestination, 50, );
  // Find path
  return NavigationHandle.FindPath();
}

///////////////////////Path Node///////////////////
state ScriptedMove
{

 /**
   * Called by APawn::moveToward when the point is unreachable
   * due to obstruction or height differences.
   */
  event MoveUnreachable(vector AttemptedDest, Actor AttemptedTarget)
  {
    //`log('Faild On Path Move');
    Popstate();
  }

  Begin:

        if(ScriptedMoveTarget != none && Pawn != none && !Pawn.ReachedDestination(ScriptedMoveTarget))
        {
           MoveToward(ScriptedMoveTarget,Focus,,,false);
        }
        Popstate();

}


///////////////////////// NavMesh////////////////
/****************************
Copy Past From 
http://x9productions.com/blog/?page_id=689
****************************/
state NavMeshSeeking
{
    //////////////////////////////////


        Begin:
                //`log("BEGIN state SCRIPTEDMOVE");
                // while we have a valid pawn and move target, and
                // we haven't reached the target yet
                //NavigationDestination = GetDestinationPosition();

                if( FindNavMeshPath() )
                {
                        NavigationHandle.SetFinalDestination(NavigationDestination);
                       // `log("FindNavMeshPath returned TRUE");
                        //FlushPersistentDebugLines();
                       // NavigationHandle.DrawPathCache(,TRUE);

                        //!Pawn.ReachedPoint here, i do not know how to handle second param, this makes the pawn
                        //stop at the first navmesh patch
//                        `Log("GetDestinationPosition before navigation (destination)"@NavigationDestination);
                        while( Pawn != None  )
                        {
                                      if(Pawn.ReachedPoint(NavigationDestination, None))
                                     {
                                         
                                         Popstate();
                                        
                                         break;
                                     }


                                     ///////////////////////////
                                if( NavigationHandle.PointReachable( NavigationDestination ) )
                                {
                                        // then move directly to the actor
                                        MoveTo( NavigationDestination, Focus, , false );
                                        //`Log("Point is reachable");
                                }
                                else
                                {
                                        //`Log("Point is not reachable");
                                        // move to the first node on the path
                                        if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
                                        {
                                               // `Log("Got next move location in TempDest " @ TempDest);
                                                // suggest move preparation will return TRUE when the edge's
                                            // logic is getting the bot to the edge point
                                                        // FALSE if we should run there ourselves
                                                //if (!NavigationHandle.SuggestMovePreparation( TempDest,self))
                                                //{
                                                        //`Log("SuggestMovePreparation in TempDest " @ TempDest);
                                                        MoveTo( TempDest, Focus, , false );
                                                //}
                                        }
                                }
                                //DistanceCheck.X = NavigationDestination.X - Pawn.Location.X;
                                //DistanceCheck.Y = NavigationDestination.Y - Pawn.Location.Y;
                                //DistanceRemaining = Sqrt((DistanceCheck.X*DistanceCheck.X) + (DistanceCheck.Y*DistanceCheck.Y));
                                //`Log("distance from pawn"@Pawn.Location@" to location "@ NavigationDestination@" is "@DistanceRemaining );
                                //`Log("Is pawn valid ?" @Pawn);
                                GotToDest = Pawn.ReachedPoint(NavigationDestination, none);
                                //`Log("Has pawn reached point ?"@GotToDest);
                                sleep(0.1);//?
                        }
                }
                else
                {
                        //give up because the nav mesh failed to find a path
                        //Worldinfo.Game.Broadcast(self, "!!!!!!!  No Nave mesh path avalible  !!!!!!!!");
                       // `warn("FindNavMeshPath failed to find a path to"@ScriptedMoveTarget);
                        ScriptedMoveTarget = none;
                        GoWithPath(NavigationDestination);//Try Path Node
                }


}  