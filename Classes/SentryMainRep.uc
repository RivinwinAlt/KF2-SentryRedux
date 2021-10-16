//This class handles replicating current server info onto the client:
//Replicates: spawned turrets for overlays, turret archetypes, materials, triggering events
//Replicates: any variable in the package that is known by name?
Class SentryMainRep extends ReplicationInfo
	transient;

var repnotify ObjectReferencer ObjRef; //Always replicated when changed?
var ObjectReferencer BaseRef;
var MaterialInstanceConstant TurSkins[3];
var KFCharacterInfo_Monster TurretArch[3];

replication
{
	if ( true )
		ObjRef;
}

//This function helps ensure there is always one spawned instance of this class on the server.
simulated static final function SentryMainRep FindContentRep( WorldInfo Level )
{
	local SentryMainRep H;
	
	//Search through spawned actors for an existing instance of this class.
	foreach Level.DynamicActors(class'SentryMainRep',H)
		if( H.ObjRef!=None )
			return H;
	//If player isnt connected to a server (or is a server itself) spawn a new instance of this class.
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
	//Creates/updates config file with default values
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
	ObjRef = BaseRef;
	if( ObjRef!=None )
		InitRep();
}

simulated function ReplicatedEvent( name VarName )
{
	if( VarName=='ObjRef' && ObjRef!=None )
		InitRep();
}

simulated final function InitRep()
{
	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		//If client, pull down materials. This might be a 400ping issue
		TurSkins[0] = CloneMIC(MaterialInstanceConstant(ObjRef.ReferencedObjects[1]));
		TurSkins[1] = CloneMIC(MaterialInstanceConstant(ObjRef.ReferencedObjects[3]));
		TurSkins[2] = CloneMIC(MaterialInstanceConstant(ObjRef.ReferencedObjects[12]));
	}
	//Copy archetypes to local variables?
	TurretArch[0] = KFCharacterInfo_Monster(ObjRef.ReferencedObjects[0]);
	TurretArch[1] = KFCharacterInfo_Monster(ObjRef.ReferencedObjects[2]);
	TurretArch[2] = KFCharacterInfo_Monster(ObjRef.ReferencedObjects[11]);
	
	//If client, update spawned turrets with local assets
	if( WorldInfo.NetMode==NM_Client )
		UpdateInstances();
}

simulated final function UpdateInstances()
{
	local SentryWeapon W;
	local SentryTurret T;

	//On client side assign meshes and materials for each spawned turret.
	//These InitDisplay functions are entirely different, from two different classes
	foreach DynamicActors(class'SentryWeapon',W)
		W.InitDisplay(Self);
	foreach WorldInfo.AllPawns(class'SentryTurret',T)
	{
		T.ContentRef = Self;
		T.InitDisplay();
	}
}

simulated static final function MaterialInstanceConstant CloneMIC( MaterialInstanceConstant B )
{
	//A reletively expensive network operation to copy materials rather than referencing them locally.
	local int i;
	local MaterialInstanceConstant M;
	
	M = new (None) class'MaterialInstanceConstant';
	M.SetParent(B.Parent);
	
	for( i=0; i<B.TextureParameterValues.Length; ++i )
		if( B.TextureParameterValues[i].ParameterValue!=None )
			M.SetTextureParameterValue(B.TextureParameterValues[i].ParameterName,B.TextureParameterValues[i].ParameterValue);
	return M;
}

//TODO Expose net update frequency to config
defaultproperties
{
   BaseRef=ObjectReferencer'tf2sentry.Arch.TurretObjList'
   NetUpdateFrequency=4.000000
   Name="Default__SentryMainRep"
   ObjectArchetype=ReplicationInfo'Engine.Default__ReplicationInfo'
}
