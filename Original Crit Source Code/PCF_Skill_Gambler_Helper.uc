class PCF_Skill_Gambler_Helper extends Info
	transient;

var bool bEnable;
var const float MinDelay;
var const AkEvent CritSound;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function ActiveEffect()
{
	if (!bEnable)
	{
		bEnable = True;
		PlayLocalEffects();
		SetTimer(MinDelay, False, NameOf(ResetEffect));
	}
}

function ResetEffect()
{
	if (Owner == None)
		Destroy();
	else
		bEnable = False;
}

reliable client function PlayLocalEffects()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();

	if (PC == None || PC.Pawn == None)
	{
		return;
	}

	PC.Pawn.PlaySoundBase(CritSound, True);
}

defaultproperties
{
	bOnlyRelevantToOwner=True

	bEnable=False
	MinDelay=0.001f
	CritSound=AkEvent'WW_Headshot_Packs.Play_WEP_Dosh_Headshot'

	Name="Default__PCF_Skill_Gambler_Helper"
}
