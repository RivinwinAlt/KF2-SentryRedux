class SentryWeapon extends KFWeap_Blunt_Pulverizer;

var repnotify int Level1Cost;
var SkeletalMeshComponent TurretPreview;
var array<string> ModeInfos;
var string AdminInfo;
var byte NumTurrets;
var bool bPendingDeploy;

replication
{
	// Variables the server should send ALL clients.
	if( true )
		Level1Cost;
}

simulated function PostBeginPlay()
{
	local SentryMainRep R;

	Super.PostBeginPlay();
	R = class'SentryMainRep'.Static.FindContentRep(WorldInfo);
	if( WorldInfo.NetMode!=NM_Client )
		Level1Cost = Class'SentryTurret'.Default.LevelCfgs[0].Cost;
	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		SetCostInfoStr();
		if( R!=None )
			InitDisplay(R);
	}
}

simulated final function InitDisplay( SentryMainRep R )
{
	TurretPreview.SetSkeletalMesh(R.TurretArch[0].CharacterMesh);
	TurretPreview.SetMaterial(0,R.TurSkins[0]);
}

simulated final function SetCostInfoStr()
{
	ModeInfos[2] = Default.ModeInfos[2]$" (Cost: "$Level1Cost@Chr(163)$")";
}
simulated event ReplicatedEvent( name VarName )
{
	switch( VarName )
	{
	case 'Level1Cost':
		SetCostInfoStr();
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}

simulated function DrawInfo( Canvas Canvas, float FontScale )
{
	local float X,Y,XL,YL;
	local byte i;

	FontScale*=1.5;
	X = Canvas.ClipX*0.99;
	Y = Canvas.ClipY*0.2;

	Canvas.SetDrawColor(255,255,64,255);
	
	for( i=0; i<ModeInfos.Length; ++i )
	{
		Canvas.TextSize(ModeInfos[i],XL,YL,FontScale,FontScale);
		Canvas.SetPos(X-XL,Y);
		Canvas.DrawText(ModeInfos[i],,FontScale,FontScale);
		Y+=YL;
	}
	if( Instigator!=None && Instigator.PlayerReplicationInfo!=None && (WorldInfo.NetMode!=NM_Client || Instigator.PlayerReplicationInfo.bAdmin) )
	{
		Canvas.SetDrawColor(255,255,128,255);
		Canvas.TextSize(AdminInfo,XL,YL,FontScale,FontScale);
		Canvas.SetPos(X-XL,Y);
		Canvas.DrawText(AdminInfo,,FontScale,FontScale);
		Y+=YL;
	}
}

reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local PlayerController PC;

	// This is the first time we have a valid Instigator (see PendingClientWeaponSet)
	if ( Instigator != None && InvManager != None
		&& WorldInfo.NetMode != NM_DedicatedServer )
	{
		PC = PlayerController(Instigator.Controller);
		if( Instigator.Controller != none && PC!=None && PC.myHUD != none )
			InitFOV(PC.myHUD.SizeX, PC.myHUD.SizeY, PC.DefaultFOV);
		if( PC!=None )
			class'SentryOverlay'.Static.GetOverlay(PC);
	}
	Super(Weapon).ClientWeaponSet(bOptionalSet, bDoNotActivate);
}
function SetOriginalValuesFromPickup( KFWeapon PickedUpWeapon )
{
	bGivenAtStart = PickedUpWeapon.bGivenAtStart;
}
function AttachThirdPersonWeapon(KFPawn P)
{
	// Create weapon attachment (server only)
	if ( Role == ROLE_Authority )
	{
		P.WeaponAttachmentTemplate = AttachmentArchetype;

		if ( WorldInfo.NetMode != NM_DedicatedServer )
			P.WeaponAttachmentChanged();
	}
}
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	local SentryTurret T;

	Super(Weapon).GivenTo(thisPawn, bDoNotActivate);

	KFInventoryManager(InvManager).AddCurrentCarryBlocks( InventorySize );
	KFPawn(Instigator).NotifyInventoryWeightChanged();
	
	NumTurrets = 0;
	foreach WorldInfo.AllPawns(class'SentryTurret',T)
		if( T.OwnerController==thisPawn.Controller && T.IsAliveAndWell() )
		{
			T.ActiveOwnerWeapon = Self;
			++NumTurrets;
		}
}

simulated function CustomFire()
{
}

static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	WeaponStats.Length = 4;

	WeaponStats[0].StatType = TWS_Damage;
	WeaponStats[0].StatValue = 50;

	// attacks per minutes (design says minute. why minute?)
	WeaponStats[1].StatType = TWS_RateOfFire;
	WeaponStats[1].StatValue = 220;  //90

	WeaponStats[2].StatType = TWS_Range;
	// This is now set in native since EffectiveRange has been moved to KFWeaponDefinition
	//WeaponStats[2].StatValue = CalculateTraderWeaponStatRange();

	WeaponStats[3].StatType = TWS_Penetration;
	WeaponStats[3].StatValue = 25;  //15
}

simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
{
	if( SentryTurret(HitActor)!=None && SentryTurret(HitActor).Health>0 )
	{
		if( WorldInfo.NetMode!=NM_Client )
		{
			if( CurrentFireMode==DEFAULT_FIREMODE )
				HitActor.HealDamage(class'SentryTurret'.Default.HealPerHit,Instigator.Controller,None);
			else if( CurrentFireMode==HEAVY_ATK_FIREMODE )
				SentryTurret(HitActor).TryToSellTurret(Instigator.Controller);
		}
		if ( !IsTimerActive(nameof(BeginPulverizerFire)) )
			SetTimer(0.001f, false, nameof(BeginPulverizerFire));
	}
}

simulated function StartFire(byte FireModeNum)
{
	if( FireModeNum==HEAVY_ATK_FIREMODE )
	{
		if( !IsFiring() )
			GoToState('DeployTurret');
	}
	else Super.StartFire(FireModeNum);
}

simulated function BeginDeployment();

reliable server function ServerDeployTurret()
{
	local SentryTurret S;
	local rotator R;
	local vector Pos,HL,HN;
	local byte i;
	
	if( Instigator.PlayerReplicationInfo==None || Instigator.PlayerReplicationInfo.Score<Level1Cost )
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 0 );
		return;
	}
	if( NumTurrets>=Class'SentryTurret'.Default.MaxTurretsPerUser )
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 3 );
		return;
	}
	if( Class'SentryTurret'.Default.MapMaxTurrets>0 )
	{
		i = 0;
		foreach WorldInfo.AllPawns(class'SentryTurret',S)
			if( S.IsAliveAndWell() && ++i>=Class'SentryTurret'.Default.MapMaxTurrets )
			{
				if( PlayerController(Instigator.Controller)!=None )
					PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 6 );
				return;
			}
	}
	
	R.Yaw = Instigator.Rotation.Yaw;
	Pos = Instigator.Location+vector(R)*120.f;

	if( Trace(HL,HN,Pos-vect(0,0,300),Pos,false,vect(30,30,50))==None )
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 2 );
		return;
	}

	foreach WorldInfo.AllPawns(class'SentryTurret',S,HL,class'SentryTurret'.Default.MinPlacementDistance)
		if( S.IsAliveAndWell() )
		{
			if( PlayerController(Instigator.Controller)!=None )
				PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 1 );
			return;
		}

	S = Instigator.Spawn(class'SentryTurret',,,Pos,R);
	if( S!=None )
	{
		S.SetTurretOwner(Instigator.Controller,Self);
		Instigator.PlayerReplicationInfo.Score-=Level1Cost;
	}
	else
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 2 );
	}
}

simulated function Tick( float Delta )
{
	local rotator R;
	local vector X;

	Super.Tick(Delta);
	
	if( bPendingDeploy )
	{
		R.Yaw = Instigator.Rotation.Yaw;
		X = vector(R);

		if( TurretPreview.HiddenGame )
			TurretPreview.SetHidden(false);
		TurretPreview.SetTranslation(Instigator.Location+X*120.f);
		TurretPreview.SetRotation(R);
	}
	else if( !TurretPreview.HiddenGame )
		TurretPreview.SetHidden(true);
}

simulated function ImpactInfo CalcWeaponFire(vector StartTrace, vector EndTrace, optional out array<ImpactInfo> ImpactList, optional vector Extent)
{
	local int i;
	local vector HitLocation, HitNormal;
	local Actor HitActor;
	local TraceHitInfo HitInfo;
	local ImpactInfo CurrentImpact;

	foreach Instigator.TraceActors(class'Actor',HitActor,HitLocation,HitNormal,EndTrace,StartTrace,Extent,HitInfo)
	{
		if( HitActor.bWorldGeometry || Pawn(HitActor)==None || SentryTurret(HitActor)!=None || (HitActor!=Instigator && !Instigator.IsSameTeam(Pawn(HitActor))) )
		{
			// Convert Trace Information to ImpactInfo type.
			CurrentImpact.HitActor		= HitActor;
			CurrentImpact.HitLocation	= HitLocation;
			CurrentImpact.HitNormal		= HitNormal;
			CurrentImpact.RayDir		= Normal(EndTrace-StartTrace);
			CurrentImpact.StartTrace	= StartTrace;
			CurrentImpact.HitInfo		= HitInfo;

			// Add this hit to the ImpactList
			ImpactList[ImpactList.Length] = CurrentImpact;

			if( PassThroughDamage(HitActor) )
				continue;

			// For pawn hits calculate an improved hit zone and direction.  The return, CurrentImpact, is
			// unaffected which is fine since it's only used for it's HitLocation and not by ProcessInstantHit()
			TraceImpactHitZones(StartTrace, EndTrace, ImpactList);

			// Iterate though ImpactList, find water, return water Impact as 'realImpact'
			// This is needed for impact effects on non-blocking water
			for (i = 0; i < ImpactList.Length; i++)
			{
				HitActor = ImpactList[i].HitActor;
				if ( HitActor != None && !HitActor.bBlockActors && HitActor.IsA('KFWaterMeshActor')  )
				{
					return ImpactList[i];
				}
			}
			break;
		}
	}

	return CurrentImpact;
}

simulated state DeployTurret extends WeaponFiring
{
	simulated function BeginState(Name PrevStateName)
	{
		bPendingDeploy = false;
		SetTimer(0.5,false,'BeginDeployment');
	}
	simulated function EndState( Name NextStateName )
	{
		if( !bPendingDeploy )
			ClearTimer('BeginDeployment');
		bPendingDeploy = false;
	}
	simulated function BeginDeployment()
	{
		bPendingDeploy = true;
	}
	simulated function StopFire(byte FireModeNum)
	{
		if( FireModeNum==HEAVY_ATK_FIREMODE )
		{
			if( bPendingDeploy )
			{
				ServerDeployTurret();
				GoToState('Active');
			}
			else
			{
				GoToState('Active');
				Super.StartFire(HEAVY_ATK_FIREMODE);
				Global.StopFire(HEAVY_ATK_FIREMODE);
			}
		}
		else Global.StopFire(FireModeNum);
	}
}

simulated state MeleeHeavyAttacking
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		Global.NotifyMeleeCollision(HitActor,HitLocation);
	}
}

exec function SentryHelp()
{
	local PlayerController P;
	local int i;
	
	P = PlayerController(Instigator.Controller);
	if( P==None )
		return;
	P.ClientMessage("To change settings, use ADMIN SentryVar <var> <val>:");
	P.ClientMessage("MaxTurretsPerUser="$class'SentryTurret'.Default.MaxTurretsPerUser);
	P.ClientMessage("MapMaxTurrets="$class'SentryTurret'.Default.MapMaxTurrets);
	P.ClientMessage("HealPerHit="$class'SentryTurret'.Default.HealPerHit);
	P.ClientMessage("MissileHitDamage="$class'SentryTurret'.Default.MissileHitDamage);
	P.ClientMessage("MinPlacementDistance="$class'SentryTurret'.Default.MinPlacementDistance);
	P.ClientMessage("HealthRegenRate="$class'SentryTurret'.Default.HealthRegenRate);
	P.ClientMessage("MaxAmmoCount0="$class'SentryTurret'.Default.MaxAmmoCount[0]);
	P.ClientMessage("MaxAmmoCount1="$class'SentryTurret'.Default.MaxAmmoCount[1]);
	P.ClientMessage("--Sentry levels (cost/damage/health):");
	for( i=0; i<ArrayCount(class'SentryTurret'.Default.Levels); ++i )
		P.ClientMessage(class'SentryTurret'.Default.Levels[i].UIName$"="$class'SentryTurret'.Default.LevelCfgs[i].Cost$"/"$class'SentryTurret'.Default.LevelCfgs[i].Damage$"/"$class'SentryTurret'.Default.LevelCfgs[i].Health);
	P.ClientMessage("--Upgrades (cost):");
	for( i=0; i<ArrayCount(class'SentryTurret'.Default.Upgrades); ++i )
		P.ClientMessage(class'SentryTurret'.Default.Upgrades[i].UIName$"="$class'SentryTurret'.Default.UpgradeCosts[i]);
}
exec function SentryVar( string S )
{
	local PlayerController P;
	local int i;
	local string V;
	
	P = PlayerController(Instigator.Controller);
	if( P==None )
		return;
	
	i = InStr(S," ");
	if( i==-1 )
		return;
	V = Mid(S,i+1);
	S = Left(S,i);
	
	switch( Caps(S) )
	{
	case "MAXTURRETSPERUSER":
		class'SentryTurret'.Default.MaxTurretsPerUser = int(V);
		break;
	case "MAPMAXTURRETS":
		class'SentryTurret'.Default.MapMaxTurrets = int(V);
		break;
	case "HEALPERHIT":
		class'SentryTurret'.Default.HealPerHit = int(V);
		break;
	case "MISSILEHITDAMAGE":
		class'SentryTurret'.Default.MissileHitDamage = int(V);
		break;
	case "MINPLACEMENTDISTANCE":
		class'SentryTurret'.Default.MinPlacementDistance = float(V);
		break;
	case "HEALTHREGENRATE":
		class'SentryTurret'.Default.HealthRegenRate = int(V);
		break;
	case "MAXAMMOCOUNT0":
		class'SentryTurret'.Default.MaxAmmoCount[0] = int(V);
		break;
	case "MAXAMMOCOUNT1":
		class'SentryTurret'.Default.MaxAmmoCount[1] = int(V);
		break;
	default:
		for( i=0; i<ArrayCount(class'SentryTurret'.Default.Levels); ++i )
			if( S~=class'SentryTurret'.Default.Levels[i].UIName )
			{
				if( !ParseLevelConfig(i,V) )
				{
					P.ClientMessage("Invalid level value '"$V$"', should be in format: cost/damage/health");
					return;
				}
				break;
			}
		if( i<ArrayCount(class'SentryTurret'.Default.Levels) )
			break;
		
		for( i=0; i<ArrayCount(class'SentryTurret'.Default.Upgrades); ++i )
			if( S~=class'SentryTurret'.Default.Upgrades[i].UIName )
			{
				class'SentryTurret'.Default.UpgradeCosts[i] = int(V);
				break;
			}
		if( i<ArrayCount(class'SentryTurret'.Default.Upgrades) )
			break;
		P.ClientMessage("Setting not found!");
		return;
	}
	P.ClientMessage("Changed value '"$S$"' to: "$V);
	class'SentryTurret'.Static.StaticSaveConfig();
}
static final function bool ParseLevelConfig( int Index, string S )
{
	local int i,Cost;
	
	i = InStr(S,"/");
	if( i==-1 )
		return false;
	Cost = int(Left(S,i));
	S = Mid(S,i+1);
	i = InStr(S,"/");
	if( i==-1 )
		return false;

	class'SentryTurret'.Default.LevelCfgs[Index].Cost = Cost;
	class'SentryTurret'.Default.LevelCfgs[Index].Damage = int(Left(S,i));
	class'SentryTurret'.Default.LevelCfgs[Index].Health = int(Mid(S,i+1));
	return true;
}


// Decompiled with UE Explorer.
defaultproperties
{
    begin object name=PrevMesh class=SkeletalMeshComponent
        ReplacementPrimitive=none
        HiddenGame=true
        bOnlyOwnerSee=true
        AbsoluteTranslation=true
        AbsoluteRotation=true
        LightingChannels=(bInitialized=true,Indoor=true,Outdoor=true)
        Translation=(X=0.0,Y=0.0,Z=-50.0)
        Scale=2.50
    object end
    // Reference: SkeletalMeshComponent'Default__SentryWeapon.PrevMesh'
    TurretPreview=PrevMesh
    ModeInfos(0)="Sentry builder:"
    ModeInfos(1)="[Fire] Repair sentry turret"
    ModeInfos(2)="[AltFire] (Hold) Construct new sentry turret"
    ModeInfos(3)="[AltFire] (Tap) Demolish your sentry turret (20% refund)"
    AdminInfo="ADMIN: Use Admin SentryHelp for commands"
    bCanBeReloaded=false
    bReloadFromMagazine=false
    InventoryGroup=EInventoryGroup.IG_Equipment
    InventorySize=1
    MagazineCapacity=0
    GroupPriority=5.0
    SpareAmmoCapacity=0
    begin object name=MeleeHelper class=KFMeleeHelperWeapon
        bUseDirectionalMelee=true
        bHasChainAttacks=true
        ChainSequence_F=/* Array type was not detected. */
        ChainSequence_L=/* Array type was not detected. */
        ChainSequence_R=/* Array type was not detected. */
        MeleeImpactCamShakeScale=0.040
        MaxHitRange=260.0
        HitboxChain=/* Array type was not detected. */
    object end
    // Reference: KFMeleeHelperWeapon'Default__SentryWeapon.MeleeHelper'
    MeleeAttackHelper=MeleeHelper
    AssociatedPerkClasses=/* Array type was not detected. */
    bCanThrow=false
    begin object name=FirstPersonMesh class=KFSkeletalMeshComponent
        SkeletalMesh=SkeletalMesh'WEP_1P_Pulverizer_MESH.Wep_1stP_Pulverizer_Rig_New'
        AnimSets(0)=AnimSet'WEP_1P_Pulverizer_ANIM.Wep_1stP_Pulverizer_Anim'
        Materials=/* Array type was not detected. */
        ReplacementPrimitive=none
        Scale3D=(X=1.60,Y=1.60,Z=1.250)
    object end
    // Reference: KFSkeletalMeshComponent'Default__SentryWeapon.FirstPersonMesh'
    Mesh=FirstPersonMesh
    bDropOnDeath=false
    begin object name=StaticPickupComponent class=StaticMeshComponent
        StaticMesh=StaticMesh'WEP_3P_Pulverizer_MESH.Wep_Pulverizer_Pickup'
        ReplacementPrimitive=none
    object end
    // Reference: StaticMeshComponent'Default__SentryWeapon.StaticPickupComponent'
    DroppedPickupMesh=StaticPickupComponent
    begin object name=StaticPickupComponent class=StaticMeshComponent
        StaticMesh=StaticMesh'WEP_3P_Pulverizer_MESH.Wep_Pulverizer_Pickup'
        ReplacementPrimitive=none
    object end
    // Reference: StaticMeshComponent'Default__SentryWeapon.StaticPickupComponent'
    PickupFactoryMesh=StaticPickupComponent
    begin object name=PrevMesh class=SkeletalMeshComponent
        ReplacementPrimitive=none
        HiddenGame=true
        bOnlyOwnerSee=true
        AbsoluteTranslation=true
        AbsoluteRotation=true
        LightingChannels=(bInitialized=true,Indoor=true,Outdoor=true)
        Translation=(X=0.0,Y=0.0,Z=-50.0)
        Scale=2.50
    object end
    // Reference: SkeletalMeshComponent'Default__SentryWeapon.PrevMesh'
    Components(0)=PrevMesh
}