// Determines how a missile will act once it is spawned by a turret
// TODO change missile target when original dies?

class ST_Proj_FragMissile extends ST_Proj_Missile
	hidedropdown;

defaultproperties
{
	Physics = PHYS_Projectile
	Speed = 3000
	MaxSpeed = 10000
	ProjFlightTemplate = ParticleSystem'WEP_RPG7_EMIT.FX_RPG7_Projectile'
	//ProjFlightTemplate = ParticleSystem'ZED_Patriarch_EMIT.FX_Patriarch_Rocket_Projectile'
	ExplosionActorClass=class'KFExplosionActor'

	Damage = 200.0
	MyDamageType = class'KFDT_Explosive_PatMissile'
	MomentumTransfer = 1000.f

	// explosion
	Begin Object Name=ExploTemplate0
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

		// Shards
		ShardClass=class'ST_Proj_Sawblade'
		NumShards=10
	End Object
	ExplosionTemplate = ExploTemplate0
	
	bAutoStartAmbientSound = true
	bStopAmbientSoundOnExplode = true
	AmbientSoundPlayEvent = AkEvent'WW_ZED_Patriarch.Play_Mini_Rocket_Trail_1'
    //AmbientSoundStopEvent = AkEvent'WW_ZED_Husk.ZED_Husk_SFX_Ranged_Shot_LP_Stop'
}