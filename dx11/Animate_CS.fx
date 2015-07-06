bool reset;
float3 gravity;
int pCount;
bool doReturn = false;
bool doReturnX = false;
float swirlFactor = 0.00001;
float steerAwayFactor = .01;
bool bounds;
bool bounce;
bool collision;
float friction;
float returnFactor;
float2 contactTimeFactor;
float bounceFactor;
bool highlightTexture;


Texture2D tex1 <string uiname="Tracking";>;
Texture2D tex2 <string uiname="Noise";>;
Texture2D colorTex <string uiname="borderTex";>;


SamplerState mySampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};



StructuredBuffer<float3> gridPos;


//Reset Position (xyz) and random damping (w)
StructuredBuffer<float3> resetData;

StructuredBuffer<float> radius;

StructuredBuffer<float> initNewPos;

//Attractors Position Buffer
StructuredBuffer<float3> attrPos;
//Attractors Data Buffer (X = radius, Y = Strength)
StructuredBuffer<float2> attrData;

//RandomDirectionBuffer
StructuredBuffer<float3> rndDir;

StructuredBuffer<int> dead;
int brwIndexShift;
float brwnStrenght;

struct particle
{
	float3 oldPos;
	float3 pos;
	float3 vel;
	float radius;
	bool collision;
	bool texCollision;
	float timer;
	float4 color;
};

RWStructuredBuffer<particle> Output : BACKBUFFER;

float1 mapRange(float1 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float2 mapRange(float2 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float3 mapRange3(float3 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}


//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(256, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID)
{
	
	
	if(dead[DTid.x] == 1) return;
	
	
	// Mapping Range
	
	float1 lookupA = mapRange(Output[DTid.x].pos.x,-1,1,0,1);
	float1 lookupB = mapRange(Output[DTid.x].pos.z,1,-1,0,1);
	
	
	float radiusAddition = 0.0;
	
	// Bounds
	if(bounds && !bounce){
		
		if(Output[DTid.x].pos.x > 1 + Output[DTid.x].radius)
		{
			Output[DTid.x].pos.x = -1 - Output[DTid.x].radius;
		}
		
		if(Output[DTid.x].pos.x < -1 - Output[DTid.x].radius)
		{
			Output[DTid.x].pos.x = 1 + Output[DTid.x].radius;
		}
		
		if(Output[DTid.x].pos.z > 1 + Output[DTid.x].radius)
		{
			Output[DTid.x].pos.z = -1 - Output[DTid.x].radius;
		}
		
		if(Output[DTid.x].pos.z < -1 - Output[DTid.x].radius)
		{
			Output[DTid.x].pos.z = 1 + Output[DTid.x].radius;
		}
	}
	
	if(bounce){
		
		
		
		if(Output[DTid.x].pos.x > 1 - (Output[DTid.x].radius/2 + radiusAddition))
		{
			
			Output[DTid.x].vel.x *= -bounceFactor;
			Output[DTid.x].vel.z *= bounceFactor;
			Output[DTid.x].pos.x = 1 - (Output[DTid.x].radius/2 + radiusAddition);
			if(bounceFactor != 1 ){
				Output[DTid.x].collision = true;
				Output[DTid.x].texCollision = true;
			}
			
		}
		
		if(Output[DTid.x].pos.x  < -1 + (Output[DTid.x].radius/2 + radiusAddition))
		{
			Output[DTid.x].vel.x *= -bounceFactor;
			Output[DTid.x].vel.z *= bounceFactor;
			Output[DTid.x].pos.x = -1 + (Output[DTid.x].radius/2 + radiusAddition);
			if(bounceFactor != 1 ){
				Output[DTid.x].collision = true;
				Output[DTid.x].texCollision = true;
				
			}
		}
		
		if(Output[DTid.x].pos.z > 1  - (Output[DTid.x].radius/2 + radiusAddition) )
		{
			Output[DTid.x].vel.z *= -bounceFactor;
			Output[DTid.x].vel.x *= bounceFactor;
			Output[DTid.x].pos.z = 1  - (Output[DTid.x].radius/2 + radiusAddition);
			if(bounceFactor != 1 ){
				Output[DTid.x].collision = true;
				Output[DTid.x].texCollision = true;
				
			}
		}
		
		if(Output[DTid.x].pos.z < -1 + (Output[DTid.x].radius/2 + radiusAddition) )
		{
			Output[DTid.x].vel.z *= -bounceFactor;
			Output[DTid.x].vel.x *= bounceFactor;
			Output[DTid.x].pos.z = -1 + (Output[DTid.x].radius/2 + radiusAddition);
			if(bounceFactor != 1 ){
				Output[DTid.x].collision = true;
				Output[DTid.x].texCollision = true;
				
			}
			
		}
		
	}
	
	if(initNewPos[DTid.x] == 1){
		Output[DTid.x].pos = resetData[DTid.x].xyz;
		Output[DTid.x].radius = radius[DTid.x];
		Output[DTid.x].vel = 0.1;
		Output[DTid.x].collision = true;
		Output[DTid.x].timer = 1;
	}
	
	if (reset)
	{
		Output[DTid.x].pos = resetData[DTid.x].xyz;
		Output[DTid.x].oldPos = resetData[DTid.x].xyz;
		Output[DTid.x].radius = radius[DTid.x];
		Output[DTid.x].vel = 0;
		Output[DTid.x].collision = false;
		Output[DTid.x].timer = 1;
	}
	
	else
	{
		float3 p = Output[DTid.x].pos;
		float3 v = Output[DTid.x].vel;
		
		
		if(pCount <= 1000){
			Output[DTid.x].radius = radius[DTid.x];
		}
		
		
		
		
		// Brownian
		uint rndIndex = DTid.x + brwIndexShift;
		rndIndex = rndIndex % pCount;
		float3 brwnForce = rndDir[rndIndex];
		v += brwnForce * brwnStrenght;
		
		v.y = 0;
		
		if(highlightTexture){
			//		Velocity Damping:
				//		v *= resetData[DTid.x].w * 1;
		}
		
		
		

		// Texture Lookup
		
		float2 lookup1;
		float4 val;
		float3 steerAway;
		float collisionCounter = 0;
		
		if(collision){
			
			
			//int angle = mapRange(Output[DTid.x].radius,0,1,360,1);
			
			float radius = Output[DTid.x].radius;
			
			
			int angle = 1;
			
			// Check collision on radius around point
			for(int i = 1; i <= 360; i+=angle){
				
				
				int currAngle = i;
				
				lookup1 = float2(lookupA + ((radius/2) * cos((currAngle))), lookupB + ((radius/2) * sin((currAngle))));
				
				// Velocity from Color tex1
				val = tex1.SampleLevel(mySampler,lookup1,0);
				
				
				float3 mappedVal1= mapRange3(float3(val.b,val.r,val.g),0,1,-1,1);
				
				steerAway = float3(mappedVal1.x,0,-mappedVal1.z);
				
				if(length(steerAway) > 0){
					collisionCounter ++;
				}
				
				v += steerAway * steerAwayFactor * radius * 100;
				
				
				
			}
			
		} else {
			
			lookup1 = float2(lookupA,lookupB);
			val = tex1.SampleLevel(mySampler,lookup1,0);
			
			float3 mappedVal1= mapRange3(float3(val.b,val.r,val.g),0,1,-1,1);
			

			steerAway = float3(mappedVal1.x,0,-mappedVal1.z);

			
			
			v += steerAway * steerAwayFactor;
			
			
		}
		
		////////////////////////////////////////
		// Set the collision
		///////////////////////////////////////
		
		
		if(length(steerAway) > 0 || collisionCounter > 0){
			
			if(Output[DTid.x].timer < 0){
				
				Output[DTid.x].collision = true;
				Output[DTid.x].texCollision = true;
				
				
				// Set collision color
				
				if(highlightTexture){
					val = colorTex.SampleLevel(mySampler,lookup1,0);
					
					float3 mappedVal1= mapRange3(float3(val.r,val.g,val.b),0,1,-1,1);
					
					Output[DTid.x].color = float4(mappedVal1.r,mappedVal1.g,mappedVal1.b,0);
				}
				
				
				
				
			}
			
		}
		
		
		
		
		
		float2 lookup2 = mapRange(Output[DTid.x].pos.xz,-1,1,0,1);
		float4 val2 = tex2.SampleLevel(mySampler,lookup2,0);
		
		float3 mappedVal2= mapRange3(float3(val2.r,val2.b,val2.g),0,1,-1,1);
		float3 swirl = float3(mappedVal2.x,0,mappedVal2.z);
		
		
		
		
		
		//Return to Start
		if(doReturn)
		{
			float3 desired = resetData[DTid.x].xyz  - Output[DTid.x].pos;
			
			desired *= returnFactor;
			desired = desired - Output[DTid.x].vel;
			
			v += desired;
			
		} else if(doReturnX)
		{
			float3 returnPos = float3(resetData[DTid.x].x, Output[DTid.x].pos.y, Output[DTid.x].pos.z);
			float3 desired = returnPos  - Output[DTid.x].pos;
			
			desired *= returnFactor;
			desired = desired - Output[DTid.x].vel;
			
			v += desired;
			
		}
		
		
		if(collision){
			
			
			// Collision Detection
			
			if(pCount < 100000){
				for(int j=0 ; j<pCount; j++)
				{
					if(length(Output[j].pos - Output[DTid.x].pos) > 0){
						
						if(length(Output[j].pos - Output[DTid.x].pos) <= (Output[DTid.x].radius+radiusAddition)
						|| length(Output[j].pos - Output[DTid.x].pos) <= (Output[j].radius+radiusAddition)){
							
							
							// Seperation Vector
							float3 s = (Output[j].pos - Output[DTid.x].pos);
							
							float s2 = 1-length(s);
							
							// radius
							v += s * -0.01 * (length(Output[j].vel*2) / (Output[DTid.x].radius)) * s2;
							Output[j].vel -= s * -0.1 * (length(Output[j].vel*2) / (Output[DTid.x].radius)) * s2;
							Output[DTid.x].collision = true;
							
							
						}
					}
					
				}
				
			}
			
			
		}
		
		
		
		// TIMER
		
		// Has a collision occured?
		if(Output[DTid.x].collision == true || Output[DTid.x].texCollision == true){
			
			// Has the timer gotten to 1?
			if(Output[DTid.x].timer >= 1){
				
				// Turn collision off
				if(collisionCounter <= 0){
					
					
					Output[DTid.x].collision = false;
					Output[DTid.x].texCollision = false;
					Output[DTid.x].timer = 1;
				}
			}
			else
			{
				// Increment timer
		
					//Output[DTid.x].timer += (contactTimeFactor.x - mapRange(Output[DTid.x].radius,0,1,0,contactTimeFactor.x*2));
					Output[DTid.x].timer += contactTimeFactor.x*0.01;
			
				
			}
			
			
		} else {
			// Decrement timer
			if(Output[DTid.x].timer > 0){
				//Output[DTid.x].timer -= (contactTimeFactor.y - mapRange(Output[DTid.x].radius,0,1,0,contactTimeFactor.y*2));
				Output[DTid.x].timer -= contactTimeFactor.y*0.01;
			}
			
			
			
		}
		
		
		
		// Special Attraction for biggest blob
		
		

		
		// Friction
		
		
		
		if(collision){
			
			v += v*(-0.1)*friction*(Output[DTid.x].radius*5);
			
			
			
			if(v.x > 0.015){
				v.x = 0.015;
			}
			if(v.x < -0.015){
				v.x = -0.015;
			}
			if(v.z > 0.015){
				v.z = 0.015;
			}
			if(v.z < -0.015){
				v.z = -0.015;
			}
			
		} else {
			v += v*(-0.1);
		}
		
		
		
		
		// Limit
		
		float3 pos = Output[DTid.x].pos;
		
		if(pos.x > 2){
			pos.x = 2;
		}
		if(pos.x < -2){
			pos.x = -2;
		}
		if(pos.z > 2){
			pos.z = 2;
		}
		if(pos.z < -2){
			pos.z = -2;
		}
		
		
		v += swirl * swirlFactor;
		v += float3(gravity.x,0,gravity.z) * 0.001;
		
		Output[DTid.x].vel = v;
		Output[DTid.x].pos = p + v;
		
	}
}




//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 simulation
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSConstantForce() ) );
	}
}
