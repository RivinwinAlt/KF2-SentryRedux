class KFProj_Missile_Sentry extends KFProj_Missile_Patriarch;

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
	SetTimer(0.05,true,'CheckHeading');
}

simulated function CheckHeading()
{
	local vector X,Y,Z;
	local float Dist;
	
	if( AimTarget==None || AimTarget.Health<=0 )
	{
		AimTarget = None;
		ClearTimer('CheckHeading');
		return;
	}
	X = (AimTarget.Location-Location);
	Dist = VSize(X);
	X = X / FMax(Dist,0.1);
	if( !FastTrace(AimTarget.Location,Location) )
	{
		// Check if we can curve to one direction to avoid hitting wall.
		Y = Normal(X Cross vect(0,0,1));
		Z = X Cross Y;
	
		if( !TestDirection(X,Z,Dist) && !TestDirection(X,-Z,Dist) && !TestDirection(X,Y,Dist) )
			TestDirection(X,-Y,Dist);
	}
	
	Y = Normal(Velocity);
	if( (Y Dot X)>0.99 )
		Y = X;
	else Y = Normal(Y+X*0.1);
	Velocity = Y*Speed;
	SetRotation(rotator(Velocity));
}

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

simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if( KFPawn(Other)!=None && KFPawn(Other).GetTeamNum()==0 )
		return;
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
}


// Decompiled with UE Explorer.
defaultproperties
{
    begin object name=FlightPointLight class=PointLightComponent
        LightColor=(R=95,G=20,B=255,A=255)
    object end
    // Reference: PointLightComponent'Default__KFProj_Missile_Sentry.FlightPointLight'
    FlightLight=FlightPointLight
    begin object name=ExploTemplate0 class=KFGameExplosion
        Damage=1000.0
        DamageRadius=750.0
        ActorClassToIgnoreForDamage=Class'KFGame.KFPawn_Human'
        ExploLight=PointLightComponent'Default__KFProj_Missile_Sentry.ExplosionPointLight'
    object end
    // Reference: KFGameExplosion'Default__KFProj_Missile_Sentry.ExploTemplate0'
    ExplosionTemplate=ExploTemplate0
    AmbientComponent=AkComponent'Default__KFProj_Missile_Sentry.AmbientAkSoundComponent'
    Damage=1000.0
    begin object name=CollisionCylinder class=CylinderComponent
        ReplacementPrimitive=none
    object end
    // Reference: CylinderComponent'Default__KFProj_Missile_Sentry.CollisionCylinder'
    CylinderComponent=CollisionCylinder
    begin object name=CollisionCylinder class=CylinderComponent
        ReplacementPrimitive=none
    object end
    // Reference: CylinderComponent'Default__KFProj_Missile_Sentry.CollisionCylinder'
    Components(0)=CollisionCylinder
    begin object name=FlightPointLight class=PointLightComponent
        LightColor=(R=95,G=20,B=255,A=255)
    object end
    // Reference: PointLightComponent'Default__KFProj_Missile_Sentry.FlightPointLight'
    Components(1)=FlightPointLight
    Components(2)=AkComponent'Default__KFProj_Missile_Sentry.AmbientAkSoundComponent'
    begin object name=CollisionCylinder class=CylinderComponent
        ReplacementPrimitive=none
    object end
    // Reference: CylinderComponent'Default__KFProj_Missile_Sentry.CollisionCylinder'
    CollisionComponent=CollisionCylinder
}