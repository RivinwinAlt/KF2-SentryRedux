//Main Turret object class extends pawn, but notably not _Monster or _Human
Class ST_TF2 extends ST_Base
	config(SentryRedux);

simulated function UpdateDisplayMesh()
{
	super.UpdateDisplayMesh();

	if(WorldInfo.NetMode != NM_DedicatedServer && Mesh.SkeletalMesh != None)
	{
		Mesh.DetachComponent(TurretSpotLight);
		Mesh.DetachComponent(TurretRedLight);
	}

	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		Mesh.AttachComponentToSocket(TurretSpotLight, 'SpotLight');
		Mesh.AttachComponentToSocket(TurretRedLight, 'SpotLight');
	}
}

defaultproperties
{
	BaseEyeHeight = 70.000000
	EyeHeight = 70.000000

	Health = 350 // Immediately overwritten by config, ensures turret is spawned with > 0 health
	HealthMax = 350 // Immediately overwritten by upgrades object, ensures turret is spawned with > 0 health

	DamageTypes(0) = class'KFDT_Ballistic' // Used for bullet damage
	DamageTypes(1) = class'KFDT_Explosive' // Used for missile damage

	ControllerClass = Class'ST_AI_Base'
	UpgradesClass = Class'ST_Upgrades_TF2'

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