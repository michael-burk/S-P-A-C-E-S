ByteAddressBuffer stream;

SamplerState mySampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};





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

struct dataOut
{
	float3 pos;

};



StructuredBuffer<particle> pData;
RWStructuredBuffer<dataOut> Output : BACKBUFFER;


//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(1, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID)
{
	
	int iterator = DTid.x;
	


		
		Output[iterator].pos = float3( asfloat(stream.Load(iterator * 12  + 12)),
									   asfloat(stream.Load(iterator * 12  + 16)),
									   asfloat(stream.Load(iterator * 12  + 20)));
		
		
	


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