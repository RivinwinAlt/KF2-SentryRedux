//Handles replicating current server info to the client

Class SentryMainRep extends ReplicationInfo
	transient;

var repnotify ObjectReferencer ObjRef;
var ObjectReferencer BaseRef;

replication
{
	if ( true )
		ObjRef;
}

// Ensures there is always one spawned instance of this class on the server.
simulated static final function SentryMainRep FindContentRep( WorldInfo Level )
{
	local SentryMainRep H;
	
	//Search through spawned actors for an existing instance of this class
	foreach Level.DynamicActors(class'SentryMainRep',H)
		if( H!=None )
			return H;
	// If server and none exists spawn a new instance
	if( Level.NetMode!=NM_Client )
	{
		H = Level.Spawn(class'SentryMainRep');
		return H;
	}
	return None;
}

function PostBeginPlay()
{
	local KFGameInfo K;

	Class'SentryTurret'.Static.UpdateConfig();

	// Replace scriptwarning spewing DialogManager.
	K = KFGameInfo(WorldInfo.Game);
	if( K!=None )
	{
		if( K.DialogManager!=None )
		{
			if( K.DialogManager.Class==Class'KFDialogManager' )
			{
				K.DialogManager.Destroy();
				K.DialogManager = Spawn(class'KFDialogManagerSentry');
			}
		}
		else if( K.DialogManagerClass==Class'KFDialogManager' )
			K.DialogManagerClass = class'KFDialogManagerSentry';
	}

	//BaseRef is defined in default properties as ObjectReferencer'tf2sentry.Arch.TurretObjList'
	//Currently being depricated
	ObjRef = BaseRef;
}

simulated function ReplicatedEvent( name VarName )
{
	if( VarName=='ObjRef' && ObjRef!=None && WorldInfo.NetMode==NM_Client )
		UpdateInstances();
}

simulated final function UpdateInstances()
{
	local SentryTurret T;

	//On client side assign meshes and materials for each spawned turret.
	//These InitDisplay functions are entirely different, from two different classes
	//foreach DynamicActors(class'KFWeap_EngWrench',W)
		//W.InitDisplay();
	foreach WorldInfo.AllPawns(class'SentryTurret',T)
	{
		//T.ContentRef = Self;
		T.UpdateDisplayMesh();
	}
}

//TODO Expose net update frequency to config
defaultproperties
{
   BaseRef = ObjectReferencer'tf2sentry.Arch.TurretObjList'
   NetUpdateFrequency = 4.000000
}
