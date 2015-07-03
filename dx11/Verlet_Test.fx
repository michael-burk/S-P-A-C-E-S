bool reset;
int pCount;
float connectorCount; // Count of pinned particles

float impulse;
float strength;
bool expand;
float restLengthFactor;

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
StructuredBuffer<int> dead;
StructuredBuffer<float> restLength;
StructuredBuffer<float2> closeLoop;



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
		//if(dead[DTid.x] == 1) return;
		
		int iterator = DTid.x;
		uint addition = 1;
		uint division = pCount / connectorCount;
		
		bool connect = true;
		
		//float rest_length = restLength[iterator];
		float rest_length;
		
		if(divide[iterator] == 1
		|| divide[iterator+addition] == 1
		|| dead[iterator] == 1
		|| dead[iterator+addition] == 1){
			connect = false;
			
			return;
		}
		
//		if(divide[iterator] == 1
//		|| dead[iterator] == 1){
//			connect = false;
//		}
		
		
		// Spring mass system and verlet integration code from
		// http://cg.alexandra.dk/tag/spring-mass-system/
		
		// Satisfy Constrains
		
		int satisfactionCount = 1;
		
		if(closeLoop[iterator].x == 1){
			satisfactionCount = 2;
		}
		
		if(iterator != pCount-1){
	
			for(int m = 0; m < satisfactionCount; m++){
				
				if(m == 1){
					addition = closeLoop[iterator].y - iterator;
				}
				
				float3 p1;
				float3 p2;
				float3 p1_to_p2;
				float3 correctionVector;
				float3 correctionVectorHalf;
				float currentDistance;
				
				rest_length = length( resetData[iterator+addition] - resetData[iterator]);
				rest_length *= restLengthFactor;
				
				
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
						
					if(connect && !expand){
						Output[iterator].pos += correctionVectorHalf;
						Output[iterator+addition].pos -= correctionVectorHalf;
						
					}
						
					if(expand){
						Output[iterator].pos -= normalize(p1_to_p2)*.00001;
						//Output[iterator+addition].pos += normalize(p1_to_p2)*.00001;
						
						
					}
						
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
		
			
				
		if(pinDown[iterator - 1] == 1
		|| pinDown[iterator + 1] == 1
		|| pinDown[iterator] == 1){
			
			Output[iterator].pos = resetData[iterator];
			Output[iterator].oldPos = resetData[iterator];
			Output[iterator].vel = 0;
			
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