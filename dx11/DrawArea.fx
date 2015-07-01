//@author: vux
//@help: standard constant shader
//@tags: color
//@credits:

float4x4 tV : VIEW;
float4x4 tVP : VIEWPROJECTION;
float4x4 tVI : VIEWINVERSE;
float4x4 tWVP : WORLDVIEWPROJECTION;

Texture2D texture2d;

float4 c <bool color=true;> = 1;
float velColMult = 1;
float alpha;

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
StructuredBuffer<particle> pData;
StructuredBuffer<float3> resetData;
StructuredBuffer<int> area;
StructuredBuffer<float2> areaCorners;

int areaCount;


float radius = 0.05f;

float3 g_positions[4]:IMMUTABLE =
{
	float3( -1, 1, 0 ),
	float3( 1, 1, 0 ),
	float3( -1, -1, 0 ),
	float3( 1, -1, 0 ),
};
float2 g_texcoords[4]:IMMUTABLE =
{
	float2(0,1),
	float2(1,1),
	float2(0,0),
	float2(1,0),
};





SamplerState g_samLinear : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

struct VS_IN
{
	uint iv : SV_VertexID;
	//float4 p: POSITION;
};

struct vs2ps
{
	float4 PosWVP: SV_POSITION ;
	float2 TexCd : TEXCOORD0 ;
	float4 Vcol : COLOR ;
	uint iv2 : PrimitiveID;
};

vs2ps VS(VS_IN input)
{
	//inititalize all fields of output struct with 0
	vs2ps Out = (vs2ps)0;
	
	float3 p = pData[input.iv].pos;
	float3 v = pData[input.iv].vel;
	//	radius = pData[input.iv].radius;
	
	Out.PosWVP = float4(p,1);// mul(float4(po.xyz,1),tVP);
	Out.Vcol = float4(saturate(v * velColMult)+0.5,1);
	Out.iv2 = input.iv;
	
	return Out;
}

float1 mapRange(float1 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}


[maxvertexcount(3)]
void GS(line vs2ps input[2], inout TriangleStream<vs2ps> SpriteStream)
{
	vs2ps output;
	output.iv2 = input[0].iv2;
	
	bool justDoIt = false;
	int currentArea;
	
		for(int m = 0; m < areaCount; m++){
			if(input[0].iv2 >= areaCorners[m].x + 1
			&& input[0].iv2 <= areaCorners[m].y - 0){
				justDoIt = true;
				currentArea = areaCount;
			}
		}
	
	if(!justDoIt){
		return;
	}
		
//		if(area[input[0].iv2] != 1
//		|| area[input[0].iv2 + 1] != 1
//		|| area[input[0].iv2 - 1] != 1
//		|| area[input[0].iv2 + 2] != 1r
//		|| area[input[0].iv2 - 2] != 1) return;
	
	
	
		//
		// Emit three new triangles
		//
		
		
		float3 p0 = input[0].PosWVP.xyz;
		float3 p1 = input[1].PosWVP.xyz;
		float3 pA = pData[areaCorners[areaCount/2].y ].pos;
		float3 pB = pData[areaCorners[areaCount/2].x +1].pos;
		//float3 pA = pData[2].pos;
		//float3 pB = pData[74].pos;
		float3 pAB = pB - pA;
		float lengthAB = length(pAB);
	
		float3 p2 = pA + normalize(pAB) * (lengthAB/2);
		//float3 p2 = pData[200].pos;

		
		
		float3 norm = mul(float3(0,0,-1),(float3x3)tVI );

		output.PosWVP = mul( float4(p0,1.0), tWVP );		
		output.TexCd = g_texcoords[0];
		output.Vcol = input[0].Vcol;
		
		SpriteStream.Append(output);
	
		output.PosWVP = mul( float4(p1,1.0), tWVP );		
		output.TexCd = g_texcoords[1];
		output.Vcol = input[1].Vcol;
		
		SpriteStream.Append(output);
	
		output.PosWVP = mul( float4(p2,1.0), tWVP );		
		output.TexCd = g_texcoords[1];
		output.Vcol = input[1].Vcol;
		
		
		SpriteStream.Append(output);
			
		
		
		SpriteStream.RestartStrip();
	
	
}


float4 PS_Tex(vs2ps In): SV_Target
{	
	float4 col;
	
	
		 col =c;
	
	
	
	
	return col;
}

technique10 Constant
{
	pass P0
	{
		
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}




