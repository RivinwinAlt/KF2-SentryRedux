// A helper class accessed through the mod's in-game menu in order to test optimizations

Class Benchmarker extends Actor;

var int Cycles;

simulated function RunAllBenchmarks()
{
	`log("ST_Benchmark: Less Than Execution Time: " $ LessThanBench());
	`log("ST_Benchmark: Not Equals Integer Execution Time: " $ NotEqualsIntegerBench());
	`log("ST_Benchmark: Multiply Integers Execution Time: " $ MultiplyIntegerBench());
	`log("ST_Benchmark: Multiply Floats Execution Time: " $ MultiplyFloatBench());
	`log("ST_Benchmark: Divide by Integer Execution Time: " $ DivideIntegerBench());
	`log("ST_Benchmark: Divide by Float Execution Time: " $ DivideFloatBench());
	`log("ST_Benchmark: Type Cast Execution Time: " $ CastBench());
	`log("ST_Benchmark: IsA Execution Time: " $ IsABench());
	//`log("ST_Benchmark:  Execution Time: " $ ());
}

simulated function float LessThanBench()
{
	local int i, TempVal;
	local float BenchTime;

	// Make sure variables are allocated
	TempVal = 1;
	i = 1;

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
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

	// Make sure variables are allocated
	TempVal = 1;
	i = 1;

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
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

	// Make sure variables are allocated
	TempVal = 1;
	i = 1;

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

	// Make sure variables are allocated
	TempVal = 1;
	i = 1;

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

	// Make sure variables are allocated
	TempVal = 1;
	i = 1;

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

	// Make sure variables are allocated
	TempVal = 1;
	i = 1;

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		TempVal = i / 2.0f;
	}
	UnClock(BenchTime);

	return BenchTime;
}

simulated function float CastBench()
{
	local int i;
	local bool TempVal;
	local float BenchTime;
	local DamageType DT;
	local KFDT_Sonic_VortexScream DTS;

	// Make sure variables are allocated
	TempVal = false;
	i = 1;
	DTS = new(Self) class'KFDT_Sonic_VortexScream';

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		DT = DTS;
		TempVal = (DT != none);
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

	// Make sure variables are allocated
	TempVal = false;
	i = 1;
	DTS = new(Self) class'KFDT_Sonic_VortexScream';

	Clock(BenchTime);
	for(i=0; i < Cycles; i++)
	{
		TempVal = DTS.IsA('DamageType');
	}
	UnClock(BenchTime);

	return BenchTime;
}

defaultproperties
{
	Cycles = 2000
}