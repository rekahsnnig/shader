Shader "raymarching/objspace_template"
{
	Properties
	{
	}
		SubShader
		{
			Tags {"RenderType" = "Queque"}
			LOD 100
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				#define DELTA 0.001
				#define MAXDISTANCE

				struct appdata
				{
					float4 vertex : POSITION;
				};

				struct v2f
				{
					float4 vertexW : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float4 screen : TEXCOORD1;
				};

				float dist(float3 p)
				{
					float s = length(p) - 0.5;
					return s;
				}

				float3 toLocal(float3 p)
				{
					return mul(unity_WorldToObject, float4(p, 1.)).xyz;
				}

				float objDist(float3 p)
				{
					return dist(toLocal(p));
				}

				float3 OgetNormal(float3 p)
				{
					float3 d = float3(DELTA,0,0);
					return normalize(float3(
						objDist(p + d) - objDist(p - d),
						objDist(p + d.yxz) - objDist(p - d.yxz),
						objDist(p + d.zyx) - objDist(p - d.zyx)
						));
				}

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.vertexW = mul(unity_ObjectToWorld,v.vertex);
					o.screen= o.vertex;
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					float2 p = i.screen.xy / i.screen;.w;
					float3 cp = _WorldSpaceCameraPos;
					float3 cd = -UNITY_MATRIX_V[2].xyz;
					float3 cu = UNITY_MATRIX_V[1].xyz;
					float3 cs = UNITY_MATRIX_V[0].xyz;
					

					float target = abs(UNITY_MATRIX_P[1][1]);

					float3 rd = normalize(float3(p.x * cs + p.y * cu + target * cd));
					
					float depth = 0.;
					float3 normal = 0;
					float3 color = 0;
					for (int i = 0; i < 99; i++)
					{
						float3 rp = cp + rd * depth;
						float d = objDist(rp);
						if (d < 0.001)
						{
							normal = OgetNormal(rp);
							color = normal;
							break;
						}
						depth += d;
					}
					return float4(color,1);
				}
			ENDCG
		}
	}
}
