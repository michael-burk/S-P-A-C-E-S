bool reset;
int pCount;
float connectorCount; // Count of pinned particles
float rest_length;
float impulse;
float strength;

bool divide;
bool pinDown;

SamplerState mySampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

//Reset Position (xyz)
StructuredBuffer<float3> resetData;

StructuredBuffer<float2> connectorPos;


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


RWStructuredBuffer<float2> Old;

RWStructuredBuffer<particle> Output : BACKBUFFER;


//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(256, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID)
{
	
	//	rest_length = 0.001;
	
	if (reset)
	{
		Output[DTid.x].vel = 0;
				Output[DTid.x].pos = resetData[DTid.x].xyz;
		////		Output[DTid.x].oldPos = float3(resetData[DTid.x].x,0,resetData[DTid.x].z);
		//		Output[DTid.x].oldPos = resetData[DTid.x].xyz;
		
		Output[DTid.x].oldPos = Output[DTid.x].pos;
		//		Output[DTid.x].collision = false;
		//		Output[DTid.x].timer = 0.1;
	}
	
	else
	{
		
		int iterator = DTid.x;
		uint addition = 1;
		uint division = pCount / connectorCount;
		
		bool connect = true;
		
		
		if(pinDown){
			if(DTid.x == 0){
				Output[DTid.x].pos = float3(connectorPos[0].x,0,connectorPos[0].y);
				
			}
			
			if(iterator == pCount-1){
				Output[DTid.x].pos = Output[DTid.x].pos = float3(connectorPos[1].x,0,connectorPos[1].y);
			}
			
			// Don't connmect certain points, so individual strings appear
			//		bool connect = true;
			
			if(divide)
			if((iterator+1) % division == 0){
				connect = false;
			}
			
		}
		
		
		
		
		
		// Spring mass system and verlet integration code from
		// http://cg.alexandra.dk/tag/spring-mass-system/
		
		// Satisfy Constrains
		if(connect && iterator != pCount-1){
			
			
			float3 p1;
			float3 p2;
			float3 p1_to_p2;
			float3 correctionVector;
			float3 correctionVectorHalf;
			float currentDistance;
			
			// Multiple iterations for better precision
			for(int k = 0; k < 20; k++){
				
				p1 = Output[iterator].pos;
				p2 = Output[iterator+addition].pos;
				
				
				p1_to_p2 =  p2 - p1;
				currentDistance = length(p1_to_p2);
				
				if(currentDistance != 0){
					saturate(currentDistance);
					
					correctionVector = mul(p1_to_p2, (1 - rest_length/currentDistance));
					correctionVectorHalf = correctionVector * strength;
					
					if(connect){
						Output[iterator].pos += correctionVectorHalf;
						Output[iterator+addition].pos -= correctionVectorHalf;
					}
					
				}
				
				
				
			}
			
			
		}
		
		
//		float3 v = Output[DTid.x].vel;
//		
//		//			// Limit
//		//
//		if(v.x > 0.015){
//			v.x = 0.015;
//		}
//		if(v.x < -0.015){
//			v.x = -0.015;
//		}
//		if(v.z > 0.015){
//			v.z = 0.015;
//		}
//		if(v.z < -0.015){
//			v.z = -0.015;
//		}
//		
//		Output[DTid.x].vel = v;
		
		if(length(Output[DTid.x].pos - Output[DTid.x].oldPos) != 0){
			// Verlet Integration
			float3 temp = Output[DTid.x].pos;
			//		float2 tempOut = Output[DTid.x].pos.xy +
			//		(Output[DTid.x].pos.xy - Output[DTid.x].oldPos.xy)*(1-0.1)  +
			//		Output[DTid.x].acc * 1;
			float3 tempOut = Output[DTid.x].pos +
			(Output[DTid.x].pos - Output[DTid.x].oldPos)*(1-impulse);
			
			
			Output[DTid.x].oldPos = temp;
			//		Output[DTid.x].acc = float2(0,0);
			//		Output[DTid.x].pos = float3(tempOut.x,0,tempOut.y);
			Output[DTid.x].pos = tempOut;
			
			
		}
		
		
		
		
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