// Defines the messages which a turret can send to players

class ST_LocalMessage extends LocalMessage
	abstract;
	//TODO Implement localization of messages? use P.myHUD.LocalizedMessage()
	//TODO implement enums for message switch

enum MessageEnums
{
	STM_LowDosh,
	STM_CloseTurret,
	STM_CloseOther,
	STM_MaxTurretsOwner,
	STM_Destroyed,
	STM_NotOwner,
	STM_MaxTurretsMap,
	STM_LowDoshUpgrade,
	STM_None
};

// Overrides to simplify and hardcode messages
static function ClientReceive(
	PlayerController PC,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local string MessageString; // Holds the message to send
	local KFPlayerController KFP;

	MessageString = static.GetString(Switch); // Get static string using a switch/case.
	if (MessageString != "")
	{
		KFP = KFPlayerController(PC);
		if(KFP != None && KFP.MyGFxHUD != None)
			KFP.MyGFxHUD.ShowNonCriticalMessage(MessageString);
	}
}

//Overrides to provide static english strings
// TODO: Reimplement localization
static function string GetString(
    optional int Sw,
    optional bool bPRI1HUD,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object Optional89Object
   )
{
	switch(Sw)
	{
	case STM_LowDosh:
		return "Not enough dosh to buy this turret";
	case STM_CloseTurret:
		return "Too close to another turret";
	case STM_CloseOther:
		return "Can't place the turret here";
	case STM_MaxTurretsOwner:
		return "You have reached the maximum turrets alive";
	case STM_Destroyed:
		return "Turret destroyed!";
	case STM_NotOwner:
		return "This turret does not belong to you!";
	case STM_MaxTurretsMap:
		return "There are too many turrets in the game";
	case STM_LowDoshUpgrade:
		return "Not enough dosh for this turret upgrade!";
	STM_None:
	default:
		return "";
	}
}

defaultproperties
{
}
