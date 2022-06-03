// A helper class accessed through the mod's in-game menu in order to test optimizations

Class Benchmarker extends Actor;

var int Cycles;

simulated function RunAllBenchmarks()
{
	local float totalBenchTime;

	Clock(totalBenchTime);
	`log("ST_Benchmark: Each Test will be run " $ Cycles $ " times";
	`log("ST_Benchmark: Filter by CanSee()   : " $ CanSeeFilterBench());
	`log("ST_Benchmark: Filter by Render Time: " $ RenderTimeFilterBench());
	`log("ST_Benchmark: Combined Filter      : " $ ModifiedRenderTimeFilterBench());
	`log("ST_Benchmark: Marco Trace Fire     : " $ MarcoTraceFireBench());
	`log("ST_Benchmark: Optimized Trace Fire : " $ NewTraceFireBench());
	`log("ST_Benchmark: Less Than Execution  : " $ LessThanBench());
	`log("ST_Benchmark: Not Equals Integer   : " $ NotEqualsIntegerBench());
	`log("ST_Benchmark: Multiply Integers    : " $ MultiplyIntegerBench());
	`log("ST_Benchmark: Multiply Floats      : " $ MultiplyFloatBench());
	`log("ST_Benchmark: Divide by Integer    : " $ DivideIntegerBench());
	`log("ST_Benchmark: Divide by Float      : " $ DivideFloatBench());
	`log("ST_Benchmark: Type Cast            : " $ CastBench());
	`log("ST_Benchmark: IsA                  : " $ IsABench());
	//`log("ST_Benchmark:  Benchamrk Name: " $ ());
	UnClock(totalBenchTime);

	`log("ST_Benchmark: All benchmarks completed in " $ totalBenchTime $ " seconds total";
}

/* EQUATIONS */

simulated function CanSeeFilterBench()
{
	local int i, filteredPawns, totalPawns;
	local float BenchTime;
	local Pawn TempPawn;
	local PlayerController LocalPlayerController;

	// Allocate variables
	LocalPlayerController = GetALocalPlayerController();

	Clock(BenchTime);
	for(i = 0; i < Cycles; i++)
	{
		foreach WorldInfo.AllPawns(class'Pawn', TempPawn, LocalPlayerController.Location, LocalPlayerController.SightRadius)
		{
			++totalPawns;
			if(LocalPlayerController.CanSee(TempPawn))
			{
				++filteredPawns;
			}
		}
	}
	UnClock(BenchTime);

	`log("ST_Benchmark: Filter by CanSee()   : Filtered " $ filteredPawns $ " of " $ totalPawns $ " Pawns";

	return BenchTime;
}

simulated function RenderTimeFilterBench()
{
	local int i, filteredPawns, totalPawns;
	local float BenchTime, ThisDot;
	local Pawn TempPawn;
	local PlayerController LocalPlayerController;

	// Allocate variables
	LocalPlayerController = GetALocalPlayerController();

	Clock(BenchTime);
	for(i = 0; i < Cycles; i++)
	{
		foreach WorldInfo.AllPawns( class'Pawn', TempPawn )
		{
			++totalPawns;
			ThisDot = ViewDir dot Normal( TempPawn.Location - LocalPlayerController.Location );
			// Calling IsAliveAndWell is an extra feature, would skew the benchmark result. Code by Pissjar.
			if( /*P.IsAliveAndWell() &&*/ `TimeSince(TempPawn.Mesh.LastRenderTime) < 0.5f && ThisDot > 0.f )
			{
				++filteredPawns;
			}
		}
	}
	UnClock(BenchTime);

	`log("ST_Benchmark: Filter by Render Time: Filtered " $ filteredPawns $ " of " $ totalPawns $ " Pawns";

	return BenchTime;
}

simulated function ModifiedRenderTimeFilterBench()
{
	local int i, filteredPawns, totalPawns;
	local float BenchTime, ThisDot;
	local Pawn TempPawn;
	local PlayerController LocalPlayerController;

	// Allocate variables
	LocalPlayerController = GetALocalPlayerController();

	Clock(BenchTime);
	for(i = 0; i < Cycles; i++)
	{
		foreach WorldInfo.AllPawns( class'Pawn', TempPawn )
		{
			++totalPawns;
			ThisDot = ViewDir dot Normal( TempPawn.Location - LocalPlayerController.Location );
			// Calling IsAliveAndWell is an extra feature, would skew the benchmark result. Code by Pissjar.
			if( /*P.IsAliveAndWell() &&*/ `TimeSince(TempPawn.Mesh.LastRenderTime) < 0.5f && ThisDot > 0.f )
			{
				++filteredPawns;
			}
		}
	}
	UnClock(BenchTime);

	`log("ST_Benchmark: Combined Filter      : Can see " $ filteredPawns $ " of " $ totalPawns $ " Pawns";

	return BenchTime;
}

simulated function MarcoTraceFireBench()
{
	local int i, TempVal;
	local float BenchTime, AccuracyMod;
	local vector Dir;

	// Allocate variables
	AccuracyMod = 0.4f;
	Dir = vect(1,0,0);

	Clock(BenchTime);
	for(i = 0; i < Cycles; i++)
	{
		Dir = Normal(Dir+VRand()*(0.075*AccurancyMod*FRand()));
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function NewTraceFireBench() // Pass in int weaponindex and use for asset indexes
{
	local int i, TempVal;
	local float BenchTime, AccuracyMod;
	local vector Dir;

	// Allocate variables
	AccuracyMod = 0.06f;
	Dir = vect(1,0,0);

	Clock(BenchTime);
	for(i = 0; i < Cycles; i++)
	{
		Dir = VRandCone(Dir, AccuracyMod);
	}
	UnClock(BenchTime);

	return BenchTime;
}

/* OPERATORS */

simulated function float LessThanBench()
{
	local int i, TempVal;
	local float BenchTime;

	Clock(BenchTime);
	for(i = 0; i < Cycles; i++)
	{
		if(i > 0)
			TempVal = i;
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function float NotEqualsIntegerBench()
{
	local int i, TempVal;
	local float BenchTime;

	Clock(BenchTime);
	for(i = 0; i < Cycles; i++)
	{
		if(i != 0)
			TempVal = i;
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function float MultiplyIntegerBench()
{
	local int i, TempVal;
	local float BenchTime;

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		TempVal = i * 2;
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function float MultiplyFloatBench()
{
	local int i, TempVal;
	local float BenchTime;

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		TempVal = i * 2.0f;
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function float DivideIntegerBench()
{
	local int i, TempVal;
	local float BenchTime;

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		TempVal = i / 2;
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function float DivideFloatBench()
{
	local int i, TempVal;
	local float BenchTime;

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		TempVal = i / 2.0f;
	}
	UnClock(BenchTime);

	return BenchTime;
}

/* NATIVE FUNCTIONS */

simulated function float CastBench()
{
	local int i;
	local bool TempVal;
	local float BenchTime;
	local DamageType DT;
	local KFDT_Sonic_VortexScream DTS;

	// Allocate variables
	DT = new(Self) class'KFDT_Sonic_VortexScream';

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		DTS = DT;
		TempVal = (DTS != none);
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function float IsABench()
{
	local int i;
	local bool TempVal;
	local float BenchTime;
	local KFDT_Sonic_VortexScream DTS;

	// Allocate variables
	DTS = new(Self) class'KFDT_Sonic_VortexScream';

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		TempVal = DT.IsA(class'KFDT_Sonic_VortexScream');
	}
	UnClock(BenchTime);

	return BenchTime;
}

defaultproperties
{
	Cycles = 2000
}