Shader "Unlit/celler3D 1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 vertexW : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.vertexW = v.vertex;
                return o;
            }
            
           float2 random22(float2 st)
            {
                st = float2(dot(st, float2(127.1, 311.7)),
                            dot(st, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }
            
             float3 random33(float3 st)
            {
                st = float3(dot(st, float3(127.1, 311.7,811.5)),
                            dot(st, float3(269.5, 183.3,211.91)),
                            dot(st, float3(511.3, 631.19,431.81))
                            );
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float4 celler3D(float3 i,float3 sepc)
            {
                float3 sep = i * sepc;
                float3 fp = floor(sep);
                float3 sp = frac(sep);
                float dist = 5.;
                float3 mp = 0.;

                [unroll]
                for (int z = -1; z <= 1; z++)
                {
                    [unroll]
                    for (int y = -1; y <= 1; y++)
                    {
                        [unroll]
                        for (int x = -1; x <= 1; x++)
                        {
                            float3 neighbor = float3(x, y ,z);
                            float3 pos = float3(random33(fp+neighbor));
                            pos = sin( (pos*6. +_Time.y/2.) )* 0.5 + 0.5;
                            float divs = length(neighbor + pos - sp);
                            mp = (dist >divs)?pos:mp;
                            dist = (dist > divs)?divs:dist;
                        }
                    }
                }
                return float4(mp,dist);
            }
            
             float3 celler2D(float2 i,float2 sepc)
            {
                float2 sep = i * sepc;
                float2 fp = floor(sep);
                float2 sp = frac(sep);
                float dist = 50.;
                float2 mp = 0.;
                
                float2 ccs = 0.;

                [unroll]
                for (int y = -1; y <= 1; y++)
                {
                    [unroll]
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 neighbor = float2(x, y);
                        float2 pos = float2(random22(fp+neighbor));
                        pos = sin(pos*6. +_Time.y/2.)* 0.5 + 0.5;
                        //pos += fp + pos;
                        //ccs += pos; 
                        float divs = length(neighbor + pos - sp);
                        mp = (dist  > divs)?pos:mp;
                        dist = (dist > divs)?divs:dist;
                    }
                }
                return float3(mp,dist);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 celler = celler3D(i.vertexW.xyz,20);
                float3 col = length(celler.xyz*celler.xyz*celler.xyz)*(1-celler.w);
                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
/*
float s;
void srand(vec2 p){
	s=sin(dot(p,vec2(423.62431,321.54323)));
}
float rand(){
	s=fract(s*32322.65432+0.12333);
	return abs(fract(s));
}
float grad(float t){
	return 6.0*pow(t,5.0)-15.0*pow(t,4.0)+10.0*pow(t,3.0);
}
mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

vec2 random22(vec2 st)
{
    st = vec2(dot(st, vec2(127.1, 311.7)),
                dot(st, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

vec2 celler2D_returnUV(vec2 i,vec2 sepc)
{
    vec2 sep = i * sepc;
    vec2 f = floor(sep);
    float dist = 5.;
	vec2 ouv = vec2(0.);
	float t = time;

	for (int y = -3; y <= 3; y++)
	{
		for (int x = -3; x <= 3; x++)
		{
			vec2 neighbor = vec2(x, y );
			srand(f + neighbor);
			vec2 o;
			o.x = rand();
			o.y = rand();
			o *= rot(t * (rand() - 0.1));
			float divs = length(f + neighbor + o - sep);
			if(divs < dist){
				dist=divs;
				ouv  = o + neighbor + f;
			}
		}
    }
    return vec2(ouv);
}
*/
