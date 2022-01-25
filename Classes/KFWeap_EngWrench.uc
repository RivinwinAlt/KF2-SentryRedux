// Defines the behavior of the Sentry Hammer (needs to be redone into Engineers Wrench)

class KFWeap_EngWrench extends KFWeap_Blunt_Pulverizer;

var transient SentryMainRep ContentRef;

var Texture2D RedTexture;
var SkeletalMeshComponent TurretPreview;
var KFCharacterInfo_Monster BaseTurretArch;
var MaterialInstanceConstant BaseTurSkin;
var array<string> ModeInfos;
var string AdminInfo;
var byte NumTurrets;
var bool bPendingDeploy;

simulated function PostBeginPlay()
{
	ContentRef = class'SentryMainRep'.Static.FindContentRep(WorldInfo);
	Super.PostBeginPlay();

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		InitConfigDependant();
		InitDisplay();
	}
}

simulated final function InitDisplay()
{
	TurretPreview.SetSkeletalMesh(BaseTurretArch.CharacterMesh);
	TurretPreview.CreateAndSetMaterialInstanceConstant(0);
	TurretPreview.SetMaterial(0, BaseTurSkin);
}

simulated final function InitConfigDependant()
{
	ModeInfos[2] = Default.ModeInfos[2]$ContentRef.LevelCfgs[0].Cost@Chr(163)$")";
	ModeInfos[3] = Default.ModeInfos[3]$Int(ContentRef.RefundMultiplier * 100)$Chr(37)$" refund)";

   bDropOnDeath = ContentRef.bCanDropWeapon;
}

simulated function DrawInfo(Canvas Canvas, float FontScale)
{
	local float X, Y, XL, YL;
	local byte i;

	FontScale *= ContentRef.WeaponTextScale; // Move this to a global variable thats only calculated once
	X = Canvas.ClipX * 0.99;
	Y = Canvas.ClipY * 0.1;

	Canvas.SetDrawColor(255, 255, 64, 255);
	
	Canvas.TextSize(ModeInfos[2], XL, YL, FontScale, FontScale); // moved outside loop
	for(i = 0; i < ModeInfos.Length; ++i)
	{
		//Canvas.TextSize(ModeInfos[2], XL, YL, FontScale, FontScale); //ModeInfos[2] is currently the longest string
		Canvas.SetPos(X - XL, Y);
		Canvas.DrawText(ModeInfos[i], , FontScale, FontScale);
		Y += YL;
	}
	if(Instigator != None && Instigator.PlayerReplicationInfo != None && (WorldInfo.NetMode != NM_Client || Instigator.PlayerReplicationInfo.bAdmin))
	{
		Canvas.SetDrawColor(255, 255, 128, 255);
		Canvas.TextSize(AdminInfo, XL, YL, FontScale, FontScale);
		Canvas.SetPos(X - XL, Y);
		Canvas.DrawText(AdminInfo, , FontScale, FontScale);
		Y += YL;
	}
}

reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local PlayerController PC;

	// This is the first time we have a valid Instigator (see PendingClientWeaponSet)
	if (Instigator != None && InvManager != None
		&& WorldInfo.NetMode != NM_DedicatedServer)
	{
		PC = PlayerController(Instigator.Controller);
		if(Instigator.Controller != none && PC != None && PC.myHUD != none)
			InitFOV(PC.myHUD.SizeX, PC.myHUD.SizeY, PC.DefaultFOV);
		if(PC != None)
			class'SentryOverlay'.Static.GetOverlay(PC);
	}

	Super(Weapon).ClientWeaponSet(bOptionalSet, bDoNotActivate);
}

function SetOriginalValuesFromPickup(KFWeapon PickedUpWeapon)
{
	local SentryTurret T;
	ContentRef = class'SentryMainRep'.Static.FindContentRep(WorldInfo);

	KFInventoryManager(InvManager).AddCurrentCarryBlocks(InventorySize);
	KFPawn(Instigator).NotifyInventoryWeightChanged();
	
	UpdateNumTurrets();

	bGivenAtStart = PickedUpWeapon.bGivenAtStart;
}

function GivenTo(Pawn thisPawn, optional bool bDoNotActivate)
{
	local SentryTurret T;
	ContentRef = class'SentryMainRep'.Static.FindContentRep(WorldInfo);

	Super(Weapon).GivenTo(thisPawn, bDoNotActivate);

	KFInventoryManager(InvManager).AddCurrentCarryBlocks(InventorySize);
	KFPawn(Instigator).NotifyInventoryWeightChanged();
	
	UpdateNumTurrets();
}

function UpdateNumTurrets()
{
	NumTurrets = 0;
	foreach WorldInfo.AllPawns(class'SentryTurret', T)
		if(T.OwnerController == thisPawn.Controller && T.IsAliveAndWell())
		{
			T.ActiveOwnerWeapon = Self;
			++NumTurrets;
		}
}

/*function AttachThirdPersonWeapon(KFPawn P)
{
	// Create weapon attachment (server only)
	if (Role == ROLE_Authority)
	{
		P.WeaponAttachmentTemplate = AttachmentArchetype;

		if (WorldInfo.NetMode != NM_DedicatedServer)
			P.WeaponAttachmentChanged();
	}
}*/

simulated function CustomFire()
{
}

/*
static simulated event SetTraderWeaponStats(out array<STraderItemWeaponStats> WeaponStats)
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
*/

simulated function BeginDeployment();

reliable server function ServerDeployTurret()
{
	local SentryTurret S;
	local rotator R;
	local vector Pos, HL, HN;
	local byte i;
	
	if(Instigator.PlayerReplicationInfo == None || Instigator.PlayerReplicationInfo.Score < ContentRef.LevelCfgs[0].Cost)
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFLocalMessage_Turret', 0);
		return;
	}
	if(NumTurrets >= ContentRef.MaxTurretsPerUser)
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFLocalMessage_Turret', 3);
		return;
	}
	if(ContentRef.MapMaxTurrets > 0)
	{
		i = 0;
		foreach WorldInfo.AllPawns(class'SentryTurret', S)
			if(S.IsAliveAndWell() && ++i >= ContentRef.MapMaxTurrets)
			{
				if(PlayerController(Instigator.Controller) != None)
					PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFLocalMessage_Turret', 6);
				return;
			}
	}
	
	R.Yaw = Instigator.Rotation.Yaw;
	Pos = Instigator.Location + vector(R) * 120.f; //120 units in front of player

	//HL = out HitLocation, HN = out HitNormal,
	if(Trace(HL, HN, Pos - vect(0, 0, 300), Pos, false, vect(30, 30, 50)) == None)
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFLocalMessage_Turret', 2);
		return;
	}

	//Check if too near another turret
	foreach WorldInfo.AllPawns(class'SentryTurret', S, HL, ContentRef.MinPlacementDistance)
		if(S.IsAliveAndWell())
		{
			if(PlayerController(Instigator.Controller) != None)
				PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFLocalMessage_Turret', 1);
			return;
		}

	//spawn a new turret
	R.Yaw += Instigator.Controller.Rotation.Pitch * ContentRef.PreviewRotationRate;
	S = Instigator.Spawn(class'SentryTurret', , , Pos, R);
	if(S != None)
	{
		S.SetTurretOwner(Instigator.Controller, Self);
		Instigator.PlayerReplicationInfo.Score -= ContentRef.LevelCfgs[0].Cost;
	}
	else
	{
		if(PlayerController(Instigator.Controller) != None)
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFLocalMessage_Turret', 2);
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
	R.Yaw += Instigator.Controller.Rotation.Pitch * ContentRef.PreviewRotationRate;
	TurretPreview.SetRotation(R);
}

/*
simulated function ImpactInfo CalcWeaponFire(vector StartTrace, vector EndTrace, optional out array<ImpactInfo> ImpactList, optional vector Extent)
{
	local int i;
	local vector HitLocation, HitNormal;
	local Actor HitActor;
	local TraceHitInfo HitInfo;
	local ImpactInfo CurrentImpact;

	foreach Instigator.TraceActors(class'Actor', HitActor, HitLocation, HitNormal, EndTrace, StartTrace, Extent, HitInfo)
	{
		if(HitActor.bWorldGeometry || Pawn(HitActor) == None || SentryTurret(HitActor) != None || (HitActor != Instigator && !Instigator.IsSameTeam(Pawn(HitActor))))
		{
			// Convert Trace Information to ImpactInfo type.
			CurrentImpact.HitActor		= HitActor;
			CurrentImpact.HitLocation	= HitLocation;
			CurrentImpact.HitNormal		= HitNormal;
			CurrentImpact.RayDir		= Normal(EndTrace - StartTrace);
			CurrentImpact.StartTrace	= StartTrace;
			CurrentImpact.HitInfo		= HitInfo;

			ImpactList[ImpactList.Length] = CurrentImpact;

			if(PassThroughDamage(HitActor))
				continue;
			TraceImpactHitZones(StartTrace, EndTrace, ImpactList);

			for (i = 0; i < ImpactList.Length; i++)
			{
				HitActor = ImpactList[i].HitActor;
				if (HitActor != None && !HitActor.bBlockActors && HitActor.IsA('KFWaterMeshActor') )
				{
					return ImpactList[i];
				}
			}
			break;
		}
	}

	return CurrentImpact;
}
*/

//TODO add condition which heals provided HealAmount
simulated function Repaired(SentryTurret T, optional int HealAmount)
{
	if(WorldInfo.NetMode != NM_Client)
	{
		T.HealDamage(ContentRef.HealPerHit, Instigator.Controller, None);
	}
}

simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
{
	if(SentryTurret(HitActor) != None && SentryTurret(HitActor).Health > 0)
	{
		if(WorldInfo.NetMode != NM_Client)
		{
			Repaired(SentryTurret(HitActor));
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

		SetTimer(ContentRef.TurretPreviewDelay, false, 'BeginDeployment');
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
		if(SentryTurret(HitActor) != None && SentryTurret(HitActor).Health > 0)
		{
			if(WorldInfo.NetMode != NM_Client)
			{
				SentryTurret(HitActor).TryToSellTurret(Instigator.Controller);
			}
			if (!IsTimerActive(nameof(BeginPulverizerFire)))
				SetTimer(0.001f, false, nameof(BeginPulverizerFire));
		} //else {
			super.NotifyMeleeCollision(HitActor, HitLocation);
		//}
	}

	simulated function byte GetWeaponStateId()
	{
		switch (MeleeAttackHelper.CurrentAttackDir)
		{
		case DIR_Forward:
		case DIR_ForwardLeft:
		case DIR_ForwardRight:
		case DIR_Backward:
		case DIR_BackwardLeft:
		case DIR_BackwardRight:
		case DIR_Left:
		case DIR_Right:			return WEP_MeleeHeavy_F;
		}

		return WEP_Idle;
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

// Overrides KFWeapon behavior to match Weapon, allows throwing
simulated function bool CanThrow()
{
	return ContentRef.bCanDropWeapon;
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
	AssociatedPerkClasses(0) = none

	PackageKey = "SentryHammer"
   FirstPersonMeshName="SentryHammer.Mesh.Wep_1stP_SentryHammer_Rig"
   FirstPersonAnimSetNames(0) = "WEP_1P_Pulverizer_ANIM.Wep_1stP_Pulverizer_Anim"
   PickupMeshName="SentryHammer.Mesh.Wep_SentryHammer_Pickup"
   AttachmentArchetypeName="SentryHammer.Wep_SentryHammer_3P"

   bCanThrow = true
   bDropOnDeath = true

	BaseTurretArch = KFCharacterInfo_Monster'tf2sentry.Arch.Turret1Arch'
	BaseTurSkin = MaterialInstanceConstant'tf2sentry.Tex.Sentry1Red'

	RedTexture=Texture2D'EngineResources.Red'

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

   ModeInfos(0) = "Sentry Hammer Controls:"
   ModeInfos(1) = "[Fire]  Repair"
   ModeInfos(2) = "[Hold AltFire]  Build (Cost: "
   ModeInfos(3) = "[AltFire]  Sell ("
   AdminInfo = "Use Admin SentryHelp for commands"

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
