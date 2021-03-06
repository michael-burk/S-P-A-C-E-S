//@author: vux
//@help: standard constant shader
//@tags: color
//@credits:

float4x4 tV : VIEW;
float4x4 tVP : VIEWPROJECTION;
float4x4 tVI : VIEWINVERSE;
float4x4 tWVP : WORLDVIEWPROJECTION;

Texture2D texture2d;
Texture2D ploppelTex;

float4 c <bool color=true;> = 1;
float velColMult = 1;
float alpha;
bool drawRadius;
bool drawCollision;
bool blowUp;
float4 highlightColor<bool color=true;>;
bool ploppel;
bool highlightTexture;
bool colorShift;


bool heading;
float4x4 tEach <string uiname="Transform Each";  >;




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

float radius = 0.05f;


StructuredBuffer<float2> texCoords;

float3 g_positions[4]:IMMUTABLE =
{
	float3( -1, 1, 0 ),
	float3( 1, 1, 0 ),
	float3( -1, -1, 0 ),
	float3( 1, -1, 0 ),
};

/*
float2 g_texcoords[4]:IMMUTABLE =
{
	float2(1,1),
	float2(0,0),
	float2(1,0),
};*/



SamplerState g_samLinear : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Border;
	AddressV = Border;
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
	
	Out.PosWVP = float4(p,1);// mul(float4(po.xyz,1),tVP);
	Out.Vcol = float4(saturate(v * velColMult)+0.5,1);
	Out.iv2 = input.iv;
	
	return Out;
}

float1 mapRange(float1 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}


[maxvertexcount(4)]
void GS(point vs2ps input[1], inout TriangleStream<vs2ps> SpriteStream)
{
	vs2ps output;
	
	
	output.iv2 = input[0].iv2;

	

	float angle = atan2(pData[output.iv2].vel.z,pData[output.iv2].vel.x) ;
	
	float size = 0.5;
	
	float cAngle = cos(angle) * 3.141592 * size;
	float sAngle = sin(angle) * 3.141592 * size;

	float4x4 rotMatrix = {	cAngle, sAngle, 0, 0,
					-sAngle, cAngle, 0, 0,
					0,	0,	1,	0,
					0,	0,	0,	1};

	
	for(int i=0; i<4; i++)
	{
		float3 position;
		float colorShiftRadius;
		
		if(colorShift){
		
			if(output.iv2 % 3 == 0){
				colorShiftRadius = 1.2;
			} 
			else if(output.iv2 % 10 == 0){
				colorShiftRadius = 1.8;
			} else {
				colorShiftRadius = 1;
			}
		}
		
		if(drawRadius){
			if(ploppel){
				if(output.iv2 == 0){
					position = (g_positions[i]*1.5)*(pData[output.iv2].radius*1);
				} else {
					position = (g_positions[i])*(pData[output.iv2].radius*1);
				}
			} else {
				position = (g_positions[i])*(pData[output.iv2].radius*1);
			}
			
		} else {
			if(drawCollision&&blowUp){
				position = g_positions[i]*((pData[output.iv2].timer * 0.5) + 1) * colorShiftRadius;
			} else {
				position = g_positions[i] * colorShiftRadius;
			}
				
		}
		
		if (!drawRadius)
		{
		position = mul( position, tEach) ;
		}
		
		if (heading)
		{
			position = mul( position, rotMatrix) ;
		}
		
		
		position = mul( position, (float3x3)tVI ) + input[0].PosWVP.xyz;		
		float3 norm = mul(float3(0,0,-1),(float3x3)tVI );
		output.PosWVP = mul( float4(position,1.0), tWVP );
				
		output.TexCd = texCoords[i] ;
		output.Vcol = input[0].Vcol;
		
		
		SpriteStream.Append(output);
	}
	
	SpriteStream.RestartStrip();
}


float4 PS_Tex(vs2ps In): SV_Target
{

	float4 col;
	float4 newHighlightColor = highlightColor;
	float4 shiftColor = 1;
	
	if(highlightTexture)
	{
		newHighlightColor = pData[In.iv2].color;
	}
	
	
	if(ploppel){
		if(In.iv2 == 0){
			col = ploppelTex.Sample( g_samLinear, In.TexCd);
		} else {
			col = texture2d.Sample( g_samLinear, In.TexCd);
		}
	} else {
		col = texture2d.Sample( g_samLinear, In.TexCd);
	}
	
	if(colorShift){
		if(In.iv2 % 2 == 0){
			shiftColor = float4(2,2,2,1);		
		}
		else if(In.iv2 % 3 == 0) {
			shiftColor = float4(1.5,1.5,1.5,1);	
			
		} 
		else if(In.iv2 % 5 == 0) {
			shiftColor = float4(0.2,0.2,0.2,1);	
			
		}
		else {
			shiftColor = float4(1,1,1,1);
		}
	}
	
	
	if(drawCollision){
		
		col *= c * shiftColor * (1 - pData[In.iv2].timer) + newHighlightColor
		*  pData[In.iv2].timer;	
		
	}else{
		
		col *= c;
	}
	
	col = c;
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

technique10 VelocityColor
{
	pass P0
	{
		
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
	}
}



