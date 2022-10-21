Class ST_InteractMessage extends KFLocalMessage_Interaction
	abstract;

enum MessageEnums
{
	STI_None,
	STI_UseTurret
};

//var localized string UseTurretMessage; // For localization implementation

// TODO: Reimplement localization
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
	case STI_None:
		return "";
	case STI_UseTurret:
		return "UPGRADE TURRET";
	}
}

static function string GetKeyBind( PlayerController PC, optional int Switch )
{
	local KFPlayerInput KFInput;
	local KeyBind BoundKey;
	local string KeyString;

	KFInput = KFPlayerInput(PC.PlayerInput);
	if( KFInput == none )
		return "";

	switch ( Switch )
	{
		case STI_UseTurret:
			KFInput.GetKeyBindFromCommand(BoundKey, default.USE_COMMAND, false);
			KeyString = KFInput.GetBindDisplayName(BoundKey);
			// KeyString = default.UseTurretMessage; // For localization implementation
			break;
	}

	return KeyString;
}