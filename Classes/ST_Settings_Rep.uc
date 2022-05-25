//Handles replicating current server info to the client

Class ST_Settings_Rep extends ReplicationInfo
	transient
	config(SentryRedux);

var float SentrySellMultiplier;

replication
{
	if(bNetDirty)
		SentrySellMultiplier;
}

// Ensures there is always one spawned instance of this class on the server.
simulated static final function ST_Settings_Rep GetSettings(WorldInfo Level)
{
	local ST_Settings_Rep H;
	
	//Search through spawned actors for an existing instance of this class
	foreach Level.DynamicActors(class'ST_Settings_Rep', H)
	{
		if(H != None)
			return H;
	}

	// If server and none exists spawn a new instance
	if(Level.NetMode != NM_Client)
	{
		H = Level.Spawn(class'ST_Settings_Rep');
		return H;
	}
	return None;
}

function PostBeginPlay()
{
	local KFGameInfo K;

	// Replace scriptwarning spewing DialogManager.
	K = KFGameInfo(WorldInfo.Game);
	if(K != None)
	{
		if(K.DialogManager != None)
		{
			if(K.DialogManager.Class == Class'KFDialogManager')
			{
				K.DialogManager.Destroy();
				K.DialogManager = Spawn(class'ST_DialogManager');
			}
		}
		else if(K.DialogManagerClass == Class'KFDialogManager')
			K.DialogManagerClass=class'ST_DialogManager';
	}
}

//TODO Expose net update frequency to config
defaultproperties
{
   //NetUpdateFrequency = 4.000000
}
