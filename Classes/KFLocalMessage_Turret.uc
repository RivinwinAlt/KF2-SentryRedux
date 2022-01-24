// Defines the messages which a turret can send to players

class KFLocalMessage_Turret extends LocalMessage
	abstract;
	//TODO Implement localization of messages? use P.myHUD.LocalizedMessage()
	//TODO implement enums for message switch

// Overrides to simplify and hardcode messages
static function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local string MessageString; // Holds the message to send
	local KFPlayerController KFP; // Create a local variable to store a cast version of P into. P is not a pawn

	MessageString = static.GetString(Switch); // Get static string using a switch/case.
	if (MessageString != "")
	{
		KFP = KFPlayerController(P);
		if(KFP != None && KFP.MyGFxHUD != None)
			KFP.MyGFxHUD.ShowNonCriticalMessage(MessageString);
			
		// How and where does it determine if the message is for the console? Is this necessary? Does it mean the player is using a console(XBox, etc)?
		if(IsConsoleMessage(Switch) && LocalPlayer(P.Player) != None && LocalPlayer(P.Player).ViewportClient != None)
			LocalPlayer(P.Player).ViewportClient.ViewportConsole.OutputText("<Turret>: "$MessageString);
	}
}

//Overrides to provide static english strings
static function string GetString(
    optional int Sw,
    optional bool bPRI1HUD,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
   )
{
	switch(Sw)
	{
	case 0:
		return "Not enough dosh to buy this turret";
	case 1:
		return "Too close to another turret";
	case 2:
		return "Can't place the turret here";
	case 3:
		return "You have reached the maximum turrets alive";
	case 4:
		return "Turret destroyed!";
	case 5:
		return "This turret does not belong to you!";
	case 6:
		return "There are too many turrets in the game";
	case 7:
		return "Not enough dosh for this turret upgrade!";
	default:
		return "";
	}
}

defaultproperties
{
}
