//Main Turret object class extends pawn, but notably not _Monster or _Human
Class ST_TF2 extends ST_Base
	config(SentryRedux);

simulated function FireShot()
{
	++DamageIndex;
	if(DamageIndex >= DamageTypes.length)
		DamageIndex = 0;
	super.FireShot();
}

defaultproperties
{
	DamageTypes = (class'KFDT_EMP', class'KFDT_Fire_HRGScorcherDoT', class'KFDT_Freeze_HRGWinterbiteImpact')

	BaseEyeHeight = 70.000000
	EyeHeight = 70.000000
	Health = 350 // Immediatly overwritten by config, ensures turret isnt spawnerd with 0 health
	HealthMax = 350 // Immediatly overwritten by config, ensures turret isnt spawnerd with 0 health
	ControllerClass = Class'STAI_Base'

	FiringSounds[0] = SoundCue'tf2sentry.Sounds.sentry_shoot_Cue'
	FiringSounds[1] = SoundCue'tf2sentry.Sounds.sentry_shoot2_Cue'
	FiringSounds[2] = SoundCue'tf2sentry.Sounds.sentry_shoot3_Cue'

	TurretArch[0] = KFCharacterInfo_Monster'tf2sentry.Arch.Turret1Arch'
	TurretArch[1] = KFCharacterInfo_Monster'tf2sentry.Arch.Turret2Arch'
	TurretArch[2] = KFCharacterInfo_Monster'tf2sentry.Arch.Turret3Arch'
	
	Levels(0) = (Icon = Texture2D'UI_LevelChevrons_TEX.UI_LevelChevron_Icon_01', UIName="Level1")
	Levels(1) = (Icon = Texture2D'UI_LevelChevrons_TEX.UI_LevelChevron_Icon_02', UIName="Level2")
	Levels(2) = (Icon = Texture2D'UI_LevelChevrons_TEX.UI_LevelChevron_Icon_04', UIName="Level3")
	
	Upgrades(0) = (Icon = Texture2D'UI_Award_PersonalMulti.UI_Award_PersonalMulti-Headshots', UIName="IronSight1")
	Upgrades(1) = (Icon = Texture2D'UI_Award_PersonalSolo.UI_Award_PersonalSolo-Headshots', UIName="IronSight2")
	Upgrades(2) = (Icon = Texture2D'UI_PerkTalent_TEX.commando.UI_Talents_Commando_Impact', UIName="EagleEye1")
	Upgrades(3) = (Icon = Texture2D'UI_PerkTalent_TEX.commando.UI_Talents_Commando_AutoFire', UIName="EagleEye2")
	Upgrades(4) = (Icon = Texture2D'UI_Award_Team.UI_Award_Team-Headshots', UIName="Headshot")
	Upgrades(5) = (Icon = Texture2D'ui_firemodes_tex.UI_FireModeSelect_Rocket', UIName="HomingRocket")
	Upgrades(6) = (Icon = Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Medic', UIName="AutoRepair")
	Upgrades(7) = (Icon = Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletBurst', UIName="Ammo")
	Upgrades(8) = (Icon = Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto', UIName="AmmoBig")
	Upgrades(9) = (Icon = Texture2D'ui_firemodes_tex.UI_FireModeSelect_Nail', UIName="Missile")
	Upgrades(10) = (Icon = Texture2D'ui_firemodes_tex.UI_FireModeSelect_NailsBurst', UIName="MissileBig")
	UpgradeNames(0) = "Iron Sight 1|This upgrade gives this turret level 1 firing precision.\n + 30 % accuracy."
	UpgradeNames(1) = "Iron Sight 2|This upgrade gives this turret level 2 firing precision.\n + 60 % accuracy."
	UpgradeNames(2) = "Eagle Eye 1|This upgrade gives this turret level 1 sight distance bonus.\n + 50 % sight distance."
	UpgradeNames(3) = "Eagle Eye 2|This upgrade gives this turret level 2 sight distance bonus.\n + 100 % sight distance."
	UpgradeNames(4) = "Head Hunter|This upgrade makes the turret aim at zed heads instead of body."
	UpgradeNames(5) = "Homing Missiles|This upgrade makes the level 3 turret fire homing missiles instead of regular missiles.\n - Requires level 3 turret to purchase!"
	UpgradeNames(6) = "Auto Repair|This upgrade makes the turret auto regain health slowly over time when haven't taken damage for 30 seconds."
	UpgradeNames(7) = "SMG Ammo|Buy 100 SMG ammo.\n(No refund for excessive ammo)"
	UpgradeNames(8) = "5x SMG Ammo|Buy 500 SMG ammo.\n(No refund for excessive ammo)"
	UpgradeNames(9) = "Missile Ammo|Buy 10 missiles.\n(No refund for excessive ammo)"
	UpgradeNames(10) = "5x Missile Ammo|Buy 50 missiles.\n(No refund for excessive ammo)"

	Begin Object Name=SpotLight1
		OuterConeAngle = 35.000000
		Radius = 2000.000000
		FalloffExponent = 3.000000
		Brightness = 1.750000
		CastShadows = False
		CastStaticShadows = False
		CastDynamicShadows = False
		bCastCompositeShadow = False
		bCastPerObjectShadows = False
		LightingChannels = (Outdoor = True)
		MaxDrawDistance = 3500.000000
	End Object
	TurretSpotLight = SpotLight1

	Begin Object Name=PointLightComponent1
		Radius = 120.000000
		Brightness = 4.000000
		LightColor = (B = 0, G = 0, R = 255, A = 255)
		CastShadows = False
		LightingChannels = (Outdoor = True)
		MaxBrightness = 1.000000
		AnimationType = 2
		AnimationFrequency = 1.000000
	End Object
	TurretRedLight = PointLightComponent1

	Begin Object Name=SkelMesh
		bUpdateSkelWhenNotRendered = False
		ReplacementPrimitive = None
		RBChannel = RBCC_GameplayPhysics
		CollideActors = True
		BlockZeroExtent = True
		LightingChannels = (bInitialized = True, Indoor = True, Outdoor = True)
		RBCollideWithChannels = (Default = True, GameplayPhysics = True, EffectPhysics = True, BlockingVolume = True)
		Translation = (X = 0.000000, Y = 0.000000, Z = -50.000000)
		Scale = 2.500000
	End Object
	Mesh = SkelMesh
	Components.Add(SkelMesh)

	Begin Object Name=CollisionCylinder
		CollisionHeight = 50.000000
		CollisionRadius = 30.000000
		ReplacementPrimitive = None
		CollideActors = True
		BlockActors = True
		BlockZeroExtent = False
	End Object
	CylinderComponent = CollisionCylinder
	Components.Add(CollisionCylinder)

	Begin Object Name=KFPawnSkeletalMeshComponent
		MinDistFactorForKinematicUpdate = 0.200000
		bSkipAllUpdateWhenPhysicsAsleep = True
		bIgnoreControllersWhenNotRendered = True
		bHasPhysicsAssetInstance = True
		bUpdateKinematicBonesFromAnimation = False
		bPerBoneMotionBlur = True
		bOverrideAttachmentOwnerVisibility = True
		bChartDistanceFactor = True
		ReplacementPrimitive = None
		RBChannel = RBCC_Pawn
		RBDominanceGroup = 20
		bOwnerNoSee = True
		bAcceptsDynamicDecals = True
		bUseOnePassLightingOnTranslucency = True
		CollideActors = True
		BlockZeroExtent = True
		BlockRigidBody = True
		RBCollideWithChannels = (Default = True, Pawn = True, Vehicle = True, BlockingVolume = True)
		Translation = (X = 0.000000, Y = 0.000000, Z = -86.000000)
		ScriptRigidBodyCollisionThreshold = 200.000000
		PerObjectShadowCullDistance = 2500.000000
		bAllowPerObjectShadows = True
		TickGroup = TG_DuringAsyncWork
	End Object
	Components.Add(KFPawnSkeletalMeshComponent)

	CollisionComponent = CollisionCylinder
}