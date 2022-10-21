// Singleton client object that saves local settings

Class ST_ClientSettings extends Info
	transient
	config(SentryReduxClient);

const CLIENT_CONFIG_VERSION = 1; // Increment this value to force a config refresh on all clients

var config int ConfigVersion;
var config bool ShowControlsOverlay;

// Ensures there is always exactly one spawned instance of this class on the Client.
simulated static final function ST_ClientSettings GetClientSettings(WorldInfo Level)
{
	local ST_ClientSettings SingletonRef;
	
	// Prevent spawning on server
	if(Level.NetMode == NM_DedicatedServer)
		return none;

	//Search through spawned actors for an existing instance of this class
	foreach Level.DynamicActors(class'ST_ClientSettings', SingletonRef)
	{
		if(SingletonRef != None)
			return SingletonRef;
	}
	
	// If none found create a new one
	return Level.Spawn(class'ST_ClientSettings');
}

function PostBeginPlay()
{
	UpdateConfig();
}

// This function creates a config file if it didn't already exist, change the value of CLIENT_CONFIG_VERSION to force a refresh
function UpdateConfig()
{
	if(ConfigVersion != CLIENT_CONFIG_VERSION)
	{
		// Default values
		ShowControlsOverlay = True;
	
		ConfigVersion = CLIENT_CONFIG_VERSION;
		SaveConfig();
	}
}

// Use to set ShowControlsOverlay
function SetShowControlsOverlay(bool NewSetting)
{
	ShowControlsOverlay = NewSetting;
	SaveConfig();
}