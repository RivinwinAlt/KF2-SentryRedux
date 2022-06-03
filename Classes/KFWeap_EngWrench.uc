// Defines the behavior of the Sentry Hammer (needs to be completely rewritten into Engineers Wrench with new model and animations)

class KFWeap_EngWrench extends KFWeap_Blunt_Pulverizer
		config(SentryRedux);

var config byte MaxTurretsPerUser, MapMaxTurrets;
var config float MinPlacementDistance, RefundMultiplier, WeaponTextScale, TurretPreviewDelay, PreviewRotationRate;
var config int  HealPerHit;
var config bool bHeavyAttackToSell, bCanDropWeapon;
var ST_GUIController PlayerGUI;

//var transient SentryMainRep 

var SkeletalMeshComponent TurretPreview;
var KFCharacterInfo_Monster BaseTurretArch;
var MaterialInstanceConstant BaseTurSkin;
var bool bPendingDeploy;
var class<ST_Turret_Base> CurrentTurretType;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if(WorldInfo.NetMode != NM_DedicatedServer)
		InitDisplay();
}

simulated final function InitDisplay()
{
	TurretPreview.SetSkeletalMesh(BaseTurretArch.CharacterMesh);
	TurretPreview.CreateAndSetMaterialInstanceConstant(0);
	TurretPreview.SetMaterial(0, BaseTurSkin);
}

reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local PlayerController PC;

	// This is the first time we have a valid Instigator (see PendingClientWeaponSet)
	if (Instigator != None && InvManager != None && WorldInfo.NetMode != NM_DedicatedServer)
	{
		PC = PlayerController(Instigator.Controller);
		if(Instigator.Controller != none && PC != None && PC.myHUD != none)
			InitFOV(PC.myHUD.SizeX, PC.myHUD.SizeY, PC.DefaultFOV);
		if(PC != None)
			class'ST_Overlay'.Static.GetOverlay(PC);
	}

	Super(Weapon).ClientWeaponSet(bOptionalSet, bDoNotActivate);
}

function SetOriginalValuesFromPickup(KFWeapon PickedUpWeapon)
{
	KFInventoryManager(InvManager).AddCurrentCarryBlocks(InventorySize);
	KFPawn(Instigator).NotifyInventoryWeightChanged();

	if(PlayerGUI == none)
		PlayerGUI = class'ST_GUIController'.static.GetGUIController(PlayerController(Instigator.Controller));
	PlayerGUI.UpdateNumTurrets();

	bGivenAtStart = PickedUpWeapon.bGivenAtStart;
}

function GivenTo(Pawn thisPawn, optional bool bDoNotActivate)
{
	Super(Weapon).GivenTo(thisPawn, bDoNotActivate);

	KFInventoryManager(InvManager).AddCurrentCarryBlocks(InventorySize);
	KFPawn(Instigator).NotifyInventoryWeightChanged();
	
	if(PlayerGUI == none)
		PlayerGUI = class'ST_GUIController'.static.GetGUIController(PlayerController(Instigator.Controller));
	PlayerGUI.UpdateNumTurrets();
}

simulated function CustomFire()
{
	// Use this to switch between default and simplified overlay styles
}

simulated function BeginDeployment(); // has to be here so that we can declare a version in heavy firing state

reliable server function ServerDeployTurret()
{
	local ST_Turret_Base S;
	local rotator R;
	local vector Pos, HL, HN;
	local byte i;
	
	if(Instigator.PlayerReplicationInfo == None || Instigator.PlayerReplicationInfo.Score < CurrentTurretType.Default.BuildCost)
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 0);
		return;
	}

	if(PlayerGUI == none)
		PlayerGUI = class'ST_GUIController'.static.GetGUIController(PlayerController(Instigator.Controller));
	if(PlayerGUI.NumTurrets >= MaxTurretsPerUser) // Maybe handle this check in the GUIController, will need to reference the replicated mod info object
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 3);
		return;
	}

	// TODO: Use SettingsRep to track this instead of iterating AllPawns each time
	if(MapMaxTurrets > 0)
	{
		i = 0;
		foreach WorldInfo.AllPawns(class'ST_Turret_Base', S)
			if(S.IsAliveAndWell() && ++i >= MapMaxTurrets)
			{
				if(PlayerController(Instigator.Controller) != None)
					PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 6);
				return;
			}
	}
	
	R.Yaw = Instigator.Rotation.Yaw;
	Pos = Instigator.Location + vector(R) * 120.f; //120 units in front of player

	//HL = out HitLocation, HN = out HitNormal,
	if(Trace(HL, HN, Pos - vect(0, 0, 300), Pos, false, vect(30, 30, 50)) == None)
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 2);
		return;
	}

	//Check if too near another turret
	foreach WorldInfo.AllPawns(class'ST_Turret_Base', S, HL, MinPlacementDistance)
		if(S.IsAliveAndWell())
		{
			if(PlayerController(Instigator.Controller) != None)
				PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 1);
			return;
		}

	//spawn a new turret
	R.Yaw += Instigator.Controller.Rotation.Pitch * PreviewRotationRate;
	S = Instigator.Spawn(CurrentTurretType, , , Pos, R);
	if(S != None)
	{
		S.SetTurretOwner(PlayerController(Instigator.Controller));
		Instigator.PlayerReplicationInfo.Score -= CurrentTurretType.Default.BuildCost;
		PlayerGUI.NumTurrets++;
	}
	else
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ST_Turret_LocalMessage', 2);
	}
}

simulated function UpdatePreview()
{
	local rotator R;
	local vector StartPos, TracedPos, HN;

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

	R.Yaw = Instigator.Rotation.Yaw;

	StartPos = Instigator.Location + vector(R) * 120.f;
	if(Trace(TracedPos, HN, StartPos - vect(0, 0, 330), StartPos, false) != None)
	{
		TurretPreview.SetTranslation(TracedPos);
	}else
	{
		TurretPreview.SetTranslation(StartPos);
	}
	R.Yaw += Instigator.Controller.Rotation.Pitch * PreviewRotationRate;
	TurretPreview.SetRotation(R);
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
			ServerDeployTurret();
		} else {
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
		//bPulverizerFireReleased = true;
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

	CurrentTurretType = class'ST_Turret_TF2' // Initial setup, will be replaced with turret-cycling code using button press
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
