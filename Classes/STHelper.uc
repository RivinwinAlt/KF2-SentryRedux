/* This class is intended to hold static functions and custom operators that are not associatted with
a specific class. Notably this class does not extend any other and is not intended to create objects or be replicated.
Functions herein must be 'static' and only use passed values. Static functions that fetch an instance of an object should
still be held in the associated class.
*/

Class STHelper extends Actor;

var string OneThousandSuffix, OneMillionSuffix, DecimalPoint;

//To add functionality implement an optional value which switches format
static final function string FormatNumber(int Value)
{
    if ( Value < 100000 )
    {
        return string(Value);
    }

    if ( Value < 1000000 )
    {
        return string(Value / 1000) $ default.OneThousandSuffix;
    }

    return string(Value / 1000000) $ "." $ string((Value % 1000000) / 100000) $ default.OneMillionSuffix;
}

static final function string FormatPercent(coerce float Lower, coerce float Upper)
{
	return string(Round((Lower / Upper) * 100.0f)) $ "%";
}

defaultproperties
{
    OneThousandSuffix="K"
    OneMillionSuffix="M"
}