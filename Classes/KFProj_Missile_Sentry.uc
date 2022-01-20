//This class determines how a missile will act once it is spawned by the turret
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
	//multiplys x by 10 or more?
	X = X / FMax(Dist,0.1);

	//trace towards target and see if theres a collision 
	if( !FastTrace(AimTarget.Location,Location) )
	{
		// Check if we can curve to one direction to avoid hitting wall.
		//takes normal of current vector and an arbitrary one?
		//TODO get normal of actor that caused collision instead
		Y = Normal(X Cross vect(0,0,1));
		Z = X Cross Y;
	
		//This code could probably be optimized to check as little as possible
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
	//dont blow up when touching players
	if( KFPawn(Other)!=None && KFPawn(Other).GetTeamNum()==0 )
		return;
	//If touching something else act like a patriarch missile
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

simulated function Destroyed()
{
	ClearTimer('CheckHeading');

	super.Destroyed();
}

//TODO expose some of these options in config
defaultproperties
{
	Damage=1000.000000

	Begin Object Name=FlightPointLight
	   LightColor=(R=255,G=20,B=95,A=255)
		Brightness=1.5f
		Radius=120.f
		FalloffExponent=10.f
		CastShadows=false
		CastStaticShadows=false
		CastDynamicShadows=false
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	FlightLight=FlightPointLight

   Begin Object Name=ExploTemplate0
      ExplosionEffects=KFImpactEffectInfo'WEP_Patriarch_ARCH.Missile_Explosion'
      Damage=1000.000000
      DamageRadius=750.000000
      DamageFalloffExponent=2.000000
      ActorClassToIgnoreForDamage=Class'KFGame.KFPawn_Human'
      MyDamageType=Class'kfgamecontent.KFDT_Explosive_PatMissile'
      ExplosionSound=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Explosion'      
      ExploLightFadeOutTime=0.500000
      CamShake=KFCameraShake'FX_CameraShake_Arch.Grenades.Default_Grenade'
      CamShakeInnerRadius=200.000000
      CamShakeOuterRadius=700.000000      
   End Object
   ExplosionTemplate=ExploTemplate0
}
