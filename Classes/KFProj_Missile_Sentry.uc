//This class describes how a missile will act once it is spawned by the turret
class KFProj_Missile_Sentry extends KFProj_Missile_Patriarch;

/*TODO change the way headings are calculated and stored so that collision
detection can be calulated in less steps and new headings can be curved to
without repeating the initial collision check.
*/
var Pawn AimTarget;

replication
{
	// Variables the server should send ALL clients.
	if( true )
		AimTarget;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	//Every .05 of a second check the missiles heading. This equates to about 20FPS
	SetTimer(0.05,true,'CheckHeading');
}

simulated function CheckHeading()
{
	//crappy vector names, they do NOT represent the x, y, and z axis
	local vector X,Y,Z;
	local float Dist;
	
	//if the target is killed or despawned stop checking heading
	if( AimTarget==None || AimTarget.Health<=0 )
	{
		AimTarget = None;
		ClearTimer('CheckHeading');
		return;
	}

	//Find distance and direction to target
	X = (AimTarget.Location-Location);
	Dist = VSize(X);
	//This math doesnt seam right. It should clamp the vectors length to
	//be a limited length not exceeding distance to the target
	X = X / FMax(Dist,0.1);

	//trace towards target and see if theres a collision 
	if( !FastTrace(AimTarget.Location,Location) )
	{
		// Check if we can curve to one direction to avoid hitting wall(/floor/static actor).
		//takes normal of current vector and an arbitrary one?
		//TODO get normal of actor that caused collision instead
		Y = Normal(X Cross vect(0,0,1));
		Z = X Cross Y;
	
		//This code is excessive. It will always test the first three directions, should only test till good vector found
		if( !TestDirection(X,Z,Dist) && !TestDirection(X,-Z,Dist) && !TestDirection(X,Y,Dist) )
			TestDirection(X,-Y,Dist);
	}
	
	//Change path to be closer to new path to produce curve rather than jerk
	Y = Normal(Velocity);
	if( (Y Dot X)>0.99 )
		Y = X;
	else Y = Normal(Y+X*0.1);
	Velocity = Y*Speed;
	SetRotation(rotator(Velocity));
}

//Im not even going to touch this with comments until i optimize it
//This function tests to see if the proposed curve away from a collision would be beneficial
simulated final function bool TestDirection( out vector Aim, vector TestAxis, float Dist )
{
	local vector V;

	// Test with a ~35 degrees angle arc.
	V = Location+Aim*(Dist*0.5)+TestAxis*0.22;
	if( FastTrace(V,Location) && FastTrace(AimTarget.Location,V) )
	{
		Aim = Normal(V-Location);
		return true;
	}
	if( Dist>1500.f ) // Test with a small arc.
	{
		V = Location+Aim*(Dist*0.5)+TestAxis*200.f;
		if( FastTrace(V,Location) && FastTrace(AimTarget.Location,V) )
		{
			Aim = Normal(V-Location);
			return true;
		}
	}
	return false;
}

//On mesh collision with an actor check if actor is on the enemy team. currently hard coded so the missile is always team 0
simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if( KFPawn(Other)!=None && KFPawn(Other).GetTeamNum()==0 )
		return;
	//If the actor is an enemy act like a patriarch missile and blow up.
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

//TODO expose some of these options in config
defaultproperties
{
   Begin Object Class=PointLightComponent Name=FlightPointLight Archetype=PointLightComponent'kfgamecontent.Default__KFProj_Missile_Patriarch:FlightPointLight'
      Radius=120.000000
      FalloffExponent=10.000000
      Brightness=1.500000
      LightColor=(B=255,G=20,R=95,A=255)
      CastShadows=False
      CastStaticShadows=False
      CastDynamicShadows=False
      bCastPerObjectShadows=False
      LightingChannels=(Outdoor=True)
      Name="FlightPointLight"
      ObjectArchetype=PointLightComponent'kfgamecontent.Default__KFProj_Missile_Patriarch:FlightPointLight'
   End Object
   FlightLight=FlightPointLight
   Begin Object Class=KFGameExplosion Name=ExploTemplate0 Archetype=KFGameExplosion'kfgamecontent.Default__KFProj_Missile_Patriarch:ExploTemplate0'
      ExplosionEffects=KFImpactEffectInfo'WEP_Patriarch_ARCH.Missile_Explosion'
      Damage=1000.000000
      DamageRadius=750.000000
      DamageFalloffExponent=2.000000
      ActorClassToIgnoreForDamage=Class'KFGame.KFPawn_Human'
      MyDamageType=Class'kfgamecontent.KFDT_Explosive_PatMissile'
      ExplosionSound=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Explosion'
      ExploLight=PointLightComponent'tf2sentrymod.Default__KFProj_Missile_Sentry:ExplosionPointLight'
      ExploLightFadeOutTime=0.500000
      CamShake=KFCameraShake'FX_CameraShake_Arch.Grenades.Default_Grenade'
      CamShakeInnerRadius=200.000000
      CamShakeOuterRadius=700.000000
      Name="ExploTemplate0"
      ObjectArchetype=KFGameExplosion'kfgamecontent.Default__KFProj_Missile_Patriarch:ExploTemplate0'
   End Object
   ExplosionTemplate=KFGameExplosion'tf2sentrymod.Default__KFProj_Missile_Sentry:ExploTemplate0'
   Begin Object Class=AkComponent Name=AmbientAkSoundComponent Archetype=AkComponent'kfgamecontent.Default__KFProj_Missile_Patriarch:AmbientAkSoundComponent'
      bStopWhenOwnerDestroyed=True
      bForceOcclusionUpdateInterval=True
      OcclusionUpdateInterval=0.100000
      Name="AmbientAkSoundComponent"
      ObjectArchetype=AkComponent'kfgamecontent.Default__KFProj_Missile_Patriarch:AmbientAkSoundComponent'
   End Object
   AmbientComponent=AmbientAkSoundComponent
   Damage=1000.000000
   Begin Object Class=CylinderComponent Name=CollisionCylinder Archetype=CylinderComponent'kfgamecontent.Default__KFProj_Missile_Patriarch:CollisionCylinder'
      CollisionHeight=5.000000
      CollisionRadius=5.000000
      ReplacementPrimitive=None
      CollideActors=True
      BlockNonZeroExtent=False
      Name="CollisionCylinder"
      ObjectArchetype=CylinderComponent'kfgamecontent.Default__KFProj_Missile_Patriarch:CollisionCylinder'
   End Object
   CylinderComponent=CollisionCylinder
   Components(0)=CollisionCylinder
   Components(1)=FlightPointLight
   Components(2)=AmbientAkSoundComponent
   CollisionComponent=CollisionCylinder
   Name="Default__KFProj_Missile_Sentry"
   ObjectArchetype=KFProj_Missile_Patriarch'kfgamecontent.Default__KFProj_Missile_Patriarch'
}
