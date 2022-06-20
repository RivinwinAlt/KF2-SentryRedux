// Defines the behavior of the Sentry Hammer (needs to be completely rewritten into Engineers Wrench with new model and animations)

class KFWeap_EngWrench extends KFWeap_Blunt_Pulverizer
	dependson(ST_Settings_Rep)
	config(SentryRedux);

var config byte MaxTurretsPerUser, MapMaxTurrets;
var config float MinPlacementDistance, RefundMultiplier, WeaponTextScale, TurretPreviewDelay;
var config int  HealPerHit;
var config bool bHeavyAttackToSell, bCanDropWeapon;

var transient ST_Settings_Rep Settings;
var transient TurretBuildInfo BuildInfo;

var SkeletalMeshComponent TurretPreview;
var KFCharacterInfo_Monster BaseTurretArch;
var MaterialInstanceConstant BaseTurSkin;
var bool bPendingDeploy;
var float PreviewRotationRate;

simulated function PostBeginPlay()
{
	if(WorldInfo.NetMode == NM_DedicatedServer)
	{
		Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);
		`log("KFWeap_EngWrench: PostBeginPlay() called on server");
	}

	Super.PostBeginPlay();

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);
		`log("KFWeap_EngWrench: PostBeginPlay() called on server");
	}

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		InitDisplay();
	}
	InitTurretSelection();
}

simulated final function InitDisplay()
{
	if(Settings == none)
		Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);

	TurretPreview.SetSkeletalMesh(BaseTurretArch.CharacterMesh);
	TurretPreview.CreateAndSetMaterialInstanceConstant(0);
	TurretPreview.SetMaterial(0, BaseTurSkin);
}

simulated function InitTurretSelection()
{
	if(Settings == none)
		Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);

	BuildInfo = Settings.PreBuildInfos[0]; // Placeholder, hardcoded to load the first buildinfo for now
	PreviewRotationRate = Settings.repPreviewRot;
}

reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local PlayerController PC;

	// This is the first time we have a valid Instigator (see PendingClientWeaponSet)
	if (Instigator != None && InvManager != None)
	{
		if(WorldInfo.NetMode != NM_DedicatedServer)
		{
			PC = PlayerController(Instigator.Controller);
			if(Instigator.Controller != none && PC != None && PC.myHUD != none)
				InitFOV(PC.myHUD.SizeX, PC.myHUD.SizeY, PC.DefaultFOV);
			if(PC != None)
				class'ST_Overlay'.Static.GetOverlay(PC, WorldInfo);
		}
	}

	Super(Weapon).ClientWeaponSet(bOptionalSet, bDoNotActivate);
}

function SetOriginalValuesFromPickup(KFWeapon PickedUpWeapon)
{
	KFInventoryManager(InvManager).AddCurrentCarryBlocks(InventorySize);
	KFPawn(Instigator).NotifyInventoryWeightChanged();

	bGivenAtStart = PickedUpWeapon.bGivenAtStart;
}

function GivenTo(Pawn thisPawn, optional bool bDoNotActivate)
{
	Super(Weapon).GivenTo(thisPawn, bDoNotActivate);

	KFInventoryManager(InvManager).AddCurrentCarryBlocks(InventorySize);
	KFPawn(Instigator).NotifyInventoryWeightChanged();
}

simulated function CustomFire()
{
	// Use this to open the turret type selection window
}

simulated function BeginDeployment();

reliable server function ServerDeployTurret()
{
	local ST_Turret_Base NewTurret;
	local rotator NewRotation;
	local vector Pos, HitLocation, HitNormal;

	if(Settings == none)
		Settings = class'ST_Settings_Rep'.Static.GetSettings(WorldInfo);
	
	// Does the player have enough Dosh?
	if(Instigator.PlayerReplicationInfo == None || Instigator.PlayerReplicationInfo.Score < BuildInfo.BuildCost)
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'ST_Turret_LocalMessage', 0 );
		return;
	}

	// Are there too many turrets on the server?
	if(!Settings.CheckNumMapTurrets(BuildInfo.TurretClass))
	{
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'ST_Turret_LocalMessage', 6 );
		return;
	}
	
	// Calculate where we'd be putting the turret
	NewRotation.Yaw = Instigator.Rotation.Yaw;
	Pos = Instigator.Location + vector(NewRotation) * 120.f; //120 units in front of player

	if(Trace(HitLocation, HitNormal, Pos - vect(0, 0, 300), Pos, false, vect(30, 30, 50)) == None)
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 2);
		return;
	}

	// Check if too near another turret
	foreach WorldInfo.AllPawns(class'ST_Turret_Base', NewTurret, HitLocation, 500)
	{
		if(NewTurret.IsAliveAndWell() && NewTurret.BuildRadius + BuildInfo.BuildRadius > VSize(NewTurret.Location - HitLocation))
		{
			if(PlayerController(Instigator.Controller) != None)
				PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 1);
			return;
		}
	}

	// Spawn a new turret
	NewRotation.Yaw += Instigator.Controller.Rotation.Pitch * PreviewRotationRate;
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
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 2);
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
	NewRotation.Yaw += Instigator.Controller.Rotation.Pitch * PreviewRotationRate;
	TurretPreview.SetRotation(NewRotation);
}

simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
{
	local ST_Turret_Base T;
	T = ST_Turret_Base(HitActor);

	if(T != None && T.Health > 0)
	{
		if(WorldInfo.NetMode != NM_Client)
		{
			T.HealDamage(HealPerHit, Instigator.Controller, None);
		}
		if (!IsTimerActive(nameof(BeginPulverizerFire)))
			SetTimer(0.001f, false, nameof(BeginPulverizerFire));
	}
}

simulated state MeleeChainAttacking
{
	simulated function byte GetWeaponStateId()
	{
		return WEP_Melee_F;
	}
	simulated function name GetMeleeAnimName(EPawnOctant AtkDir, EMeleeAttackType AtkType)
	{
		// Update our animation rate before changing weapon state to stay synced
		UpdateWeaponAttachmentAnimRate( GetThirdPersonAnimRate() );

		// update state id to match new attack direction
		KFPawn(Instigator).WeaponStateChanged(GetWeaponStateId());

		// primary / normal strikes and chain attacks
		if ( AtkType == ATK_Combo )
		{
			return MeleeComboChainAnim_F;
		}
		return MeleeAttackAnim_F;
	}
}

simulated state MeleeHeavyAttacking
{
	simulated event BeginState(Name PreviousStateName)
	{
		NotifyBeginState();
		//bPulverizerFireReleased = false;

		SetTimer(TurretPreviewDelay, false, 'BeginDeployment');
	}

	simulated function BeginDeployment()
	{
		bPendingDeploy = true;
		SetTimer(0.01, true, 'UpdatePreview');
	}

	simulated function StopFire(byte FireModeNum)
	{
		local KFPerk InstigatorPerk;

		if(bPendingDeploy)
		{
			bPendingDeploy = false;
			// Does the player own the max turrets already?
			if(!Settings.CheckNumPlayerTurrets(BuildInfo.TurretClass))
			{
				if( PlayerController(Instigator.Controller)!=None )
					PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'ST_Turret_LocalMessage', 3 );
				Super(KFWeap_MeleeBase).StopFire(FireModeNum);
				bPulverizerFireReleased = true;
				return;
			}
			ServerDeployTurret();
		}
		else
		{
			InstigatorPerk = GetPerk();
			if( InstigatorPerk != none )
			{
				SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
			}

			if ( bUsingSights )
			{
				ZoomOut(false, default.ZoomOutTime);
			}

			TimeWeaponFiring(CurrentFireMode);
			
			if ( Instigator.IsLocallyControlled() ) // from KFWeap_MeleeBase
			{
				KFPlayerController(Instigator.Controller).PauseMoveInput(0.1f);
			}
		}
		ClearTimer('BeginDeployment');

		Super(KFWeap_MeleeBase).StopFire(FireModeNum);
		bPulverizerFireReleased = true;
	}

	simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
	{
		local ST_Turret_Base T;
		T = ST_Turret_Base(HitActor);
		if(T != None && T.Health > 0)
		{
			if(WorldInfo.NetMode != NM_Client)
			{
				T.TryToSellTurret(Instigator.Controller);
			}
			if (!IsTimerActive(nameof(BeginPulverizerFire)))
				SetTimer(0.001f, false, nameof(BeginPulverizerFire));
		}
		super.NotifyMeleeCollision(HitActor, HitLocation);
	}

	simulated function byte GetWeaponStateId()
	{
		//if (MeleeAttackHelper.CurrentAttackDir != DIR_None)
		//{
			return WEP_MeleeHeavy_F;
		//}
		//return WEP_Idle;
	}
	simulated function name GetMeleeAnimName(EPawnOctant AtkDir, EMeleeAttackType AtkType)
	{
		// heavy damage attacks
		if ( AtkType == ATK_DrawStrike )
		{
			return MeleeDrawStrikeAnim;
		}
		return MeleeHeavyAttackAnim_F;
	}
}

// Overrides KFWeapon.uc behavior to match Weapon.uc, allows weapon dropping
simulated function bool CanThrow()
{
	return bCanDropWeapon;
}

// Hardcoding to overhead swing
simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	return ShootAnim_F;
}

simulated function Rotator GetPulverizerAim( vector StartFireLoc )
{
	local Rotator R;
	R = GetAdjustedAim(StartFireLoc);
	R.Pitch -= 2048;
	return R;
}

defaultproperties
{
	//DroppedPickupClass=class'PU_InteractDroppedPickup' // THIS ONE LINE ENABLES PU_HoveringWeaponInfo.uc and PU_InteractDroppedPickup.uc FUNCTIONALITY

	AssociatedPerkClasses(0) = none

	PackageKey = "SentryHammer"
   FirstPersonMeshName="SentryHammer.Mesh.Wep_1stP_SentryHammer_Rig"
   FirstPersonAnimSetNames(0) = "WEP_1P_Pulverizer_ANIM.Wep_1stP_Pulverizer_Anim"
   PickupMeshName="SentryHammer.Mesh.Wep_SentryHammer_Pickup"
   AttachmentArchetypeName="SentryHammer.Wep_SentryHammer_3P"

   bCanThrow = true
   bDropOnDeath = true

	BaseTurretArch = KFCharacterInfo_Monster'Turret_TF2.Arch.Turret1Arch'
	BaseTurSkin = MaterialInstanceConstant'Turret_TF2.Mat.Sentry1Red'

   Begin Object Class=SkeletalMeshComponent Name=PrevMesh
      ReplacementPrimitive = None
      HiddenGame = True
      bOnlyOwnerSee = True
      AbsoluteTranslation = True
      AbsoluteRotation = True
      LightingChannels = (bInitialized = True, Indoor = True, Outdoor = True)
      Translation = (X = 0.000000, Y = 0.000000, Z = -50.000000) //z was -50
      Scale = 2.500000
   End Object
   TurretPreview = PrevMesh

   InventoryGroup = IG_Equipment
   InventorySize = 1
   MagazineCapacity(0) = 0
   bCanBeReloaded = False
   bReloadFromMagazine = False
   GroupPriority = 5.000000
   SpareAmmoCapacity(0) = 0

   Begin Object Name=MeleeHelper_0
		MaxHitRange = 260 //used to be 190
		WorldImpactEffects = KFImpactEffectInfo'FX_Impacts_ARCH.Blunted_melee_impact'
		// Override automatic hitbox creation (advanced)
		HitboxChain.Add((BoneOffset = (Y = -3, Z = 170)))
		HitboxChain.Add((BoneOffset = (Y = +3, Z = 150)))
		HitboxChain.Add((BoneOffset = (Y = -3, Z = 130)))
		HitboxChain.Add((BoneOffset = (Y = +3, Z = 110)))
		HitboxChain.Add((BoneOffset = (Y = -3, Z = 90)))
		HitboxChain.Add((BoneOffset = (Y = +3, Z = 70)))
		HitboxChain.Add((BoneOffset = (Y = -3, Z = 50)))
		HitboxChain.Add((BoneOffset = (Y = +3, Z = 30)))
		HitboxChain.Add((BoneOffset = (Y = -3, Z = 10)))
		MeleeImpactCamShakeScale = 0.01f // 0.04f
		ChainSequence_F = (DIR_Forward, DIR_Forward, DIR_Forward, DIR_Forward)
		ChainSequence_B = (DIR_Forward, DIR_Forward, DIR_Forward, DIR_Forward)
		ChainSequence_L = (DIR_Forward, DIR_Forward, DIR_Forward, DIR_Forward, DIR_Forward)
		ChainSequence_R = (DIR_Forward, DIR_Forward, DIR_Forward, DIR_Forward, DIR_Forward)
	End Object

   Components.Add(PrevMesh)
}
