simulated state ScriptedMove1
{
	simulated event Tick(float DeltaTime)
	{
		super.Tick(DeltaTime);
		
		if (Pawn != None && !Pawn.ReachedDestination(ScriptedMoveTarget) &&
			ScriptedMoveTarget != None && KFPawn(ScriptedMoveTarget).IsAliveAndWell() &&
			VSize(MyPawn.Location-ScriptedMoveTarget.Location)>=450)
		{
			if (ActorReachable(ScriptedMoveTarget) || LineOfSightTo(ScriptedMoveTarget))
			{
				ProcessMoveTo(ScriptedMoveTarget.location,pawn.Location);
			}

			else
			{
				MoveTarget = FindPathToward(ScriptedMoveTarget);
				if (MoveTarget != None)
				{
					// move to the first node on the path
					ProcessMoveTo(MoveTarget.location,pawn.Location);
				}
				// `warn("Failed to find path to "@ScriptedMoveTarget$" attempting to find a closest node");
				else
				{
					foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint',NavP,P,800)
					{
						if(TargetNavP==None)
						{
							TargetNavP=Navp;
						}
						else if(LineOfSightTo(TargetNavP) && Vsize(ScriptedMoveTarget.Location-NavP.Location)<Vsize(ScriptedMoveTarget.Location-TargetNavP.Location))
						{
							TargetNavP=NavP;
						}
					}
					if(TargetNavP==None)
					{
						ScriptedMoveTarget = None;
						`warn("Failed to find a closet pathndoe");
					}
					else
					{
						ProcessMoveTo(TargetNavP.Location,pawn.Location);
						//MoveTo(TargetNavP.location,pawn.Location);
						//MoveTo(TargetNavP.Location);
					}
					TargetNavP=None;
				}
			}
		}
		else
		{
			GotoState('Previous State');
		}
	}
}

simulated final function ProcessMoveTo(vector end, vector start)
{
	local vector distance;
	distance = end - start;
	SetDestinationPosition(distance);
	SetFocalPoint(distance);
	MyPawn.Velocity = Normal(distance) * 800;
}