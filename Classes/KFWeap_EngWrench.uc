// Defines the behavior of the Sentry Hammer (needs to be completely rewritten into Engineers Wrench with new model and animations)

class KFWeap_EngWrench extends KFWeap_MeleeBase
	dependson(ST_Settings_Rep);

var transient ST_Settings_Rep Settings;
var transient TurretBuildInfo BuildInfo;

var SkeletalMeshComponent TurretPreview;
var bool bPendingDeploy, bTurretDeployed; // Used by firing state code to determine when to place a turret vs attack
var array<string> ModeInfos;

// TODO: Move this data to Settings_Rep buildInfo array
var KFCharacterInfo_Monster BaseTurretArch;
var MaterialInstanceConstant BaseTurSkin;


simulated function PostBeginPlay()
{
	local ST_Overlay tempOverlay;

	// First hammer on map will return None client side while the server creates the Settings object and replicates ; RetryTurretSelection() solves this
	Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);

	tempOverlay = class'ST_Overlay'.Static.GetOverlay(GetALocalPlayerController(), WorldInfo);

	Super.PostBeginPlay();

	InitTurretSelection();
}

simulated function InitTurretSelection()
{
	if(Settings == none || !Settings.bInitialized)
	{
		SetTimer(0.3, false, 'RetryTurretSelection'); // Arbitrary time, err on the side of slower
		return;
	}

	BuildInfo = Settings.PreBuildInfos[Settings.repStartingTurret];
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		SetOverlayValues();

		// TODO: rather than using BaseTurretArch here load the info based on BuildInfo
		TurretPreview.SetSkeletalMesh(BaseTurretArch.CharacterMesh);
		TurretPreview.CreateAndSetMaterialInstanceConstant(0);
		TurretPreview.SetMaterial(0, BaseTurSkin);
	}
}

simulated function RetryTurretSelection()
{
	if(Settings == none)
		Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);
	InitTurretSelection();
}

simulated function SetOverlayValues()
{
	ModeInfos[0] = Default.ModeInfos[0] $ BuildInfo.TypeString;
	ModeInfos[3] = Default.ModeInfos[3] $ BuildInfo.BuildCost;
}

reliable server function ServerDeployTurret()
{
	local ST_Turret_Base NewTurret;
	local ST_Settings_Rep ServerSideSettings;
	local rotator NewRotation;
	local vector Pos, HitLocation, HitNormal;

	ServerSideSettings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);
	
	// Does the player have enough Dosh?
	if(Instigator.PlayerReplicationInfo == None || Instigator.PlayerReplicationInfo.Score < BuildInfo.BuildCost)
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'ST_LocalMessage', 0 );
		return;
	}

	// Are there too many turrets on the server?
	if(!ServerSideSettings.CheckNumMapTurrets(BuildInfo.TurretClass))
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'ST_LocalMessage', 6 );
		return;
	}
	
	// Calculate where we'd be putting the turret
	NewRotation.Yaw = Instigator.Rotation.Yaw;
	Pos = Instigator.Location + vector(NewRotation) * 120.f; //120 units in front of player

	if(Trace(HitLocation, HitNormal, Pos - vect(0, 0, 300), Pos, false, vect(30, 30, 50)) == None)
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_LocalMessage', 2);
		return;
	}

	// Check if too near another turret
	foreach WorldInfo.AllPawns(class'ST_Turret_Base', NewTurret, HitLocation, 500)
	{
		if(NewTurret.IsAliveAndWell() && NewTurret.BuildRadius + BuildInfo.BuildRadius > VSize(NewTurret.Location - HitLocation))
		{
			if(PlayerController(Instigator.Controller) != None)
				PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_LocalMessage', 1);
			return;
		}
	}

	// Spawn a new turret
	NewRotation.Yaw += Instigator.Controller.Rotation.Pitch * ServerSideSettings.repPreviewRot;
	NewTurret = Instigator.Spawn(BuildInfo.TurretClass, , , HitLocation, NewRotation);
	
	if(NewTurret != None)
	{
		NewTurret.SetTurretOwner(PlayerController(Instigator.Controller));
		NewTurret.BuildRadius = BuildInfo.BuildRadius;
		NewTurret.DoshValue = BuildInfo.BuildCost;
		Instigator.PlayerReplicationInfo.Score -= BuildInfo.BuildCost;
	}
	else
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_LocalMessage', 2);
	}
}

simulated function UpdatePreview()
{
	local rotator NewRotation;
	local vector StartPos, TracedPos, HitNormal;

	if(Instigator == None)
		bPendingDeploy = false;
	if(!bPendingDeploy)
	{
		ClearTimer('UpdatePreview');
		TurretPreview.SetHidden(true);
		return;
	}
	
	if(TurretPreview.HiddenGame)
		TurretPreview.SetHidden(false);

	NewRotation.Yaw = Instigator.Rotation.Yaw;

	StartPos = Instigator.Location + vector(NewRotation) * 120.f;
	if(Trace(TracedPos, HitNormal, StartPos - vect(0, 0, 330), StartPos, false) != None)
	{
		TurretPreview.SetTranslation(TracedPos);
	}else
	{
		TurretPreview.SetTranslation(StartPos);
	}
	NewRotation.Yaw += Instigator.Controller.Rotation.Pitch * Settings.repPreviewRot;
	TurretPreview.SetRotation(NewRotation);
}

// Confusing, but this state is when you press AltFire, TODO: connect to turret selection menu
simulated state TurretSelectionMenu extends MeleeBlocking
{
}

simulated function BeginDeployment()
{
	bPendingDeploy = true;
	SetTimer(0.01, true, 'UpdatePreview');
}

simulated state MeleeChainAttacking
{
	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		local ST_Turret_Base T;

		if(Role == ROLE_Authority)
		{
			T = ST_Turret_Base(HitActor);
			if(T != None)
				T.HealDamage(Settings.repHitRepair, Instigator.Controller, None);
		}
	}
}

simulated function StartFire(byte FireModeNum)
{
	if(bPendingDeploy && FireModeNum == DEFAULT_FIREMODE)
	{
		// Does the player own the max turrets already?
		if(!Settings.CheckNumPlayerTurrets(BuildInfo.TurretClass))
		{
			if( PlayerController(Instigator.Controller) != None )
				PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'ST_LocalMessage', 3 );
		}
		else
		{
			bPendingDeploy = false;
			bTurretDeployed = true;
			ServerDeployTurret();
		}
	}
	else
	{
		Super.StartFire(FireModeNum);
	}
}

simulated state MeleeDeployTurret extends MeleeBlocking
{
	simulated function BeginState(name PreviousStateName)
	{
		bTurretDeployed = false;
		if(WorldInfo.NetMode != NM_DedicatedServer && Settings != none && Settings.bInitialized && Settings.CheckNumPlayerTurrets(BuildInfo.TurretClass)) // <- This is so that the first user who doesn't have a Settings for less than a second doesnt have issues
		{
			SetTimer(Settings.repPrevDelay, false, nameof(BeginDeployment));
		}

		// SetSlowMovement(true);
		
		Super.BeginState(PreviousStateName);
	}

	simulated function EndState(Name NextStateName)
	{
		ClearTimer(nameof(BeginDeployment));
		bPendingDeploy = false;

		// SetSlowMovement(false);
	}
}

// Overrides KFWeapon.uc behavior to match Weapon.uc, allows weapon dropping
simulated function bool CanThrow()
{
	if(Settings != none && Settings.bInitialized)
	{
		return Settings.repDropHammer;
	}
	else
	{
		return false;
	}
}

defaultproperties
{
	PackageKey = "Pulverizer" // I have no idea what this does
	//DroppedPickupClass=class'PU_InteractDroppedPickup' // THIS ONE LINE ENABLES PU_HoveringWeaponInfo.uc and PU_InteractDroppedPickup.uc FUNCTIONALITY

	// Trader
	AssociatedPerkClasses(0) = none // To show up in all perk menus
	ParryDamageMitigationPercent=0.40 // From pulverizer
	BlockDamageMitigation=0.50 // From pulverizer

	// Weapon mesh/material
	FirstPersonMeshName="SentryHammer.Mesh.Wep_1stP_SentryHammer_Rig"
	FirstPersonAnimSetNames(0) = "WEP_1P_Pulverizer_ANIM.Wep_1stP_Pulverizer_Anim"
	PickupMeshName="SentryHammer.Mesh.Wep_SentryHammer_Pickup"
	AttachmentArchetypeName="SentryHammer.Wep_SentryHammer_3P"

	// Turret preview mesh/material // TODO: this will be moving to Settings_Rep
	BaseTurretArch = KFCharacterInfo_Monster'Turret_TF2.Arch.Turret1Arch'
	BaseTurSkin = MaterialInstanceConstant'Turret_TF2.Mat.Sentry1Red'

	// Inventory
	WeaponSelectTexture=Texture2D'ui_weaponselect_tex.UI_WeaponSelect_Pulverizer'
	InventoryGroup = IG_Equipment
	InventorySize = 1
	GroupPriority = 5.0f
	bDropOnDeath = false // Overriden when CanThrow() returns true, IE: never change this value

	// Blocking
	ParryStrength=5 // From pulverizer

	// Firing Modes
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BluntMelee'
	InstantHitDamage(DEFAULT_FIREMODE)=80
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Bludgeon_Pulverizer'

	FiringStatesArray(HEAVY_ATK_FIREMODE)=MeleeDeployTurret
	FireModeIconPaths(HEAVY_ATK_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BluntMelee'
	InstantHitDamage(HEAVY_ATK_FIREMODE)=145
	InstantHitDamageTypes(HEAVY_ATK_FIREMODE)=class'KFDT_Bludgeon_PulverizerHeavy'
	AmmoCost(HEAVY_ATK_FIREMODE)=0

	// Controls Overlay
	ModeInfos(0) = "Turret: "
	ModeInfos(1) = "Repair: [LMB]"
	ModeInfos(2) = "Build: [RMB] + [LMB]"
	ModeInfos(3) = "Cost: $"

	// Open turret selection menu
	/*
	FireModeIconPaths(BLOCK_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_ShotgunSingle'
	FiringStatesArray(BLOCK_FIREMODE)=OpenTurretSelection
	WeaponFireTypes(BLOCK_FIREMODE)=EWFT_Custom
	*/

	// Block Effects
	BlockSound=AkEvent'WW_WEP_Bullet_Impacts.Play_Block_MEL_Hammer'
	ParrySound=AkEvent'WW_WEP_Bullet_Impacts.Play_Parry_Wood'

	Begin Object Class=SkeletalMeshComponent Name=PrevMesh
		ReplacementPrimitive = None
		HiddenGame = True
		bOnlyOwnerSee = True
		AbsoluteTranslation = True
		AbsoluteRotation = True
		LightingChannels = (bInitialized = True, Indoor = True, Outdoor = True)
		Translation = (X = 0.0, Y = 0.0, Z = -50.0) //z was -50
		Scale = 2.5
	End Object
	TurretPreview = PrevMesh

	Begin Object Name=MeleeHelper_0
		MaxHitRange = 190 // Up from 150, tested as high as 260
		WorldImpactEffects = KFImpactEffectInfo'FX_Impacts_ARCH.Blunted_melee_impact'

		HitboxChain.Add((BoneOffset=(Y=-3,Z=170)))
		HitboxChain.Add((BoneOffset=(Y=+3,Z=150)))
		HitboxChain.Add((BoneOffset=(Y=-3,Z=130)))
		HitboxChain.Add((BoneOffset=(Y=+3,Z=110)))
		HitboxChain.Add((BoneOffset=(Y=-3,Z=90)))
		HitboxChain.Add((BoneOffset=(Y=+3,Z=70)))
		HitboxChain.Add((BoneOffset=(Y=-3,Z=50)))
		HitboxChain.Add((BoneOffset=(Y=+3,Z=30)))
		HitboxChain.Add((BoneOffset=(Y=-3,Z=10)))

		ChainSequence_F=(DIR_ForwardRight, DIR_ForwardLeft, DIR_ForwardRight, DIR_ForwardLeft)
		ChainSequence_B=(DIR_ForwardRight, DIR_ForwardLeft, DIR_ForwardRight, DIR_ForwardLeft)
		ChainSequence_L=(DIR_ForwardRight, DIR_ForwardLeft, DIR_ForwardRight, DIR_ForwardLeft)
		ChainSequence_R=(DIR_ForwardRight, DIR_ForwardLeft, DIR_ForwardRight, DIR_ForwardLeft)

		//bUseDirectionalMelee=false
		//bHasChainAttacks=false

		MeleeImpactCamShakeScale = 0.01f // from 0.04f
	End Object

	Components.Add(PrevMesh)

	// WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.1f), (Stat=EWUS_Damage1, Scale=1.1f), (Stat=EWUS_Damage2, Scale=1.1f), (Stat=EWUS_Weight, Add=1)))
	// WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.2f), (Stat=EWUS_Damage1, Scale=1.2f), (Stat=EWUS_Damage2, Scale=1.2f), (Stat=EWUS_Weight, Add=2)))
}
