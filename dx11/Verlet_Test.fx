bool reset;
int pCount;
float connectorCount; // Count of pinned particles

float impulse;
float strength;

SamplerState mySampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

//Reset Position (xyz)
StructuredBuffer<float3> resetData;

StructuredBuffer<float2> connectorPos;

StructuredBuffer<int> pinDown;
StructuredBuffer<int> divide;
StructuredBuffer<float> restLength;


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
	
	
	if (reset)
	{
		Output[DTid.x].vel = 0;
		Output[DTid.x].pos = resetData[DTid.x].xyz;
		Output[DTid.x].oldPos = Output[DTid.x].pos;

	}
	
	else
	{
		
		int iterator = DTid.x;
		uint addition = 1;
		uint division = pCount / connectorCount;
		
		bool connect = true;
		
		float rest_length = restLength[iterator];
		
		if(divide[iterator] == 1 || divide[iterator+addition] == 1){
			connect = false;
		}
		
		
		// Spring mass system and verlet integration code from
		// http://cg.alexandra.dk/tag/spring-mass-system/
		
		// Satisfy Constrains
		if(iterator != pCount-1){
			
			
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
		
		
		
		if(length(Output[DTid.x].pos - Output[DTid.x].oldPos) != 0){
			// Verlet Integration
			float3 temp = Output[DTid.x].pos;
			float3 tempOut = Output[DTid.x].pos +
			(Output[DTid.x].pos - Output[DTid.x].oldPos)*(1-impulse);
			
			
			Output[DTid.x].oldPos = temp;
			Output[DTid.x].pos = tempOut;
			
			
		}
		
		
		if(pinDown[iterator] == 1){
			
			Output[iterator].pos = resetData[iterator];
			
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