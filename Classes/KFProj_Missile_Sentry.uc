// Determines how a missile will act once it is spawned by a turret
// TODO change missile target when original dies?

class KFProj_Missile_Sentry extends KFProjectile
	hidedropdown;

var Pawn AimTarget;
var float InitialSpeed;
var vector Dir;

/** Flight light */
var PointLightComponent FlightLight;

replication
{
	if (true)
		AimTarget;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	//Every .05 of a second check the missiles heading. This equates to about 20FPS
	SetTimer(0.05f, true, 'CheckHeading');
}

simulated function CheckHeading()
{
	local vector TarRay, Heading;
	local float Dist;
	
	// If the target is killed or despawned stop checking heading and exit
	if(AimTarget == None || AimTarget.Health <= 0)
	{
		AimTarget = None;
		ClearTimer('CheckHeading');
		return;
	}


	//Find distance and direction to target
	TarRay = (AimTarget.Location - Location);
	Dist = VSize(TarRay);

	// Reduces Ray length down to 1.0 by deviding by itself
	// TarRay = TarRay / FMax(Dist, 0.1); // FMax avoids dividing by 0 or negatives
	// REPLACED WITH
	if(Dist > 1)
		TarRay = Normal(TarRay);

	// Change path to be closer to new path to produce curve rather than jerk
	Heading = Normal(Velocity);
	if((Heading Dot TarRay) > 0.95)
		Heading = TarRay;
	else Heading = Normal(Heading + (TarRay * 0.1));

	Velocity = Heading * Speed;
	SetRotation(rotator(Velocity)); // Set rotation to that of either Velocity or Heading
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();
	
	/** Since bIgnoreInstigator is transient, its value must be defined here */
	ExplosionTemplate.bIgnoreInstigator = true;
}

simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if(FlightLight != none && WorldInfo.NetMode != NM_DedicatedServer)
	{
		FlightLight.Radius = 120.f + FlightLight.default.Radius * Abs(Cos(WorldInfo.TimeSeconds * (DeltaTime * 800.f)));
	}

	// Finalize rotation
	SetRotation(rotator(Velocity));
}

/** Overloaded to apply direct damage on hit */
simulated function bool TraceProjHitZones(Pawn P, vector EndTrace, vector StartTrace, out array<ImpactInfo> out_Hits)
{
	if(P != none)
	{
		P.TakeDamage(Damage, InstigatorController, StartTrace, MomentumTransfer * Normal(Velocity), MyDamageType, , self);
		return true;
	}

	return false;
}

/** Stops projectile simulation without destroying it.  Projectile is resting, essentially. */
simulated protected function StopSimulating()
{
	super.StopSimulating();

	FlightLight.SetEnabled(false);
	DetachComponent(FlightLight);
	FlightLight = none;
}

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	// Dont blow up when touching players
	if(KFPawn(Other) != None && KFPawn(Other).GetTeamNum() == 0)
		return;
	// If touching something else explode. Maybe. Dud?
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

simulated function Destroyed()
{
	ClearTimer('CheckHeading');
	super.Destroyed();
}

defaultproperties
{
	Physics = PHYS_Projectile
	Speed = 3000
	MaxSpeed = 10000
	ProjFlightTemplate = ParticleSystem'WEP_RPG7_EMIT.FX_RPG7_Projectile'
	//ProjFlightTemplate = ParticleSystem'ZED_Patriarch_EMIT.FX_Patriarch_Rocket_Projectile'
	ExplosionActorClass=class'KFExplosionActor'

	Damage = 1000.0
	MyDamageType = class'KFDT_Explosive_PatMissile'
	MomentumTransfer = 1000.f

	// CollideActors = true allows detection via OverlappingActors or CollidingActors (for Siren scream)
	Begin Object Name=CollisionCylinder
		CollisionRadius = 5.0f
		CollisionHeight = 5.0f
		BlockNonZeroExtent = false
		CollideActors = true
	End Object

	// Flight light
	Begin Object Class=PointLightComponent Name=FlightPointLight
	    LightColor = (R = 255, G = 20, B = 95, A = 255)
		Brightness = 1.5f
		Radius = 120.0f
		FalloffExponent = 10.0f
		CastShadows = false
		CastStaticShadows = false
		CastDynamicShadows = false
		bCastPerObjectShadows = false
		bEnabled = true
		LightingChannels = (Indoor = TRUE, Outdoor = TRUE, bInitialized = TRUE)
	End Object
	FlightLight = FlightPointLight
	Components.Add(FlightPointLight)

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor = (R = 245, G = 190, B = 140, A = 255)
		Brightness = 4.0f
		Radius = 1400.0f
		FalloffExponent = 10.0f
		CastShadows = False
		CastStaticShadows = FALSE
		CastDynamicShadows = False
		bCastPerObjectShadows = false
		bEnabled = FALSE
		LightingChannels = (Indoor = TRUE, Outdoor = TRUE, bInitialized = TRUE)
	End Object

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage = 1000.0
		DamageRadius = 750
		DamageFalloffExponent = 2.0f
		DamageDelay = 0.0f

		ActorClassToIgnoreForDamage = Class'KFGame.KFPawn_Human'

		// Damage Effects
		MyDamageType = class'KFDT_Explosive_PatMissile'
		KnockDownStrength = 100
		FractureMeshRadius = 200.0f
		FracturePartVel = 500.0f
		ExplosionEffects = KFImpactEffectInfo'WEP_Patriarch_ARCH.Missile_Explosion'
		ExplosionSound = AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Explosion'

        // Dynamic Light
        ExploLight = ExplosionPointLight
        ExploLightStartFadeOutTime = 0.0f
        ExploLightFadeOutTime = 0.5f

		// Camera Shake
		CamShake = CameraShake'FX_CameraShake_Arch.Grenades.Default_Grenade'
		CamShakeInnerRadius = 200
		CamShakeOuterRadius = 700
		CamShakeFalloff = 1.0f
		bOrientCameraShakeTowardsEpicenter = true
	End Object
	ExplosionTemplate = ExploTemplate0

	Begin Object Class=AkComponent Name=AmbientAkSoundComponent
		bStopWhenOwnerDestroyed = true
        bForceOcclusionUpdateInterval = true
        OcclusionUpdateInterval = 0.1f
    End Object
    AmbientComponent = AmbientAkSoundComponent
    Components.Add(AmbientAkSoundComponent)

	bAutoStartAmbientSound = true
	bStopAmbientSoundOnExplode = true
	AmbientSoundPlayEvent = AkEvent'WW_ZED_Patriarch.Play_Mini_Rocket_Trail_1'
    //AmbientSoundStopEvent = AkEvent'WW_ZED_Husk.ZED_Husk_SFX_Ranged_Shot_LP_Stop'
}