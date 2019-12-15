//http://tips.hecomi.com/entry/2016/09/26/014539
//参考にさせてもらいました
Shader "raymarching/obj_template"
{
	Properties
	{
	}
	SubShader
	{
		Tags {"RenderType" = "Queque"}
		LOD 100
		Cull off
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#define DELTA 0.001
			#define M(x,y) (x - y * floor(x/y)) - y/2.
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screen : TEXCOORD0;
				float4 vertexW : TEXCOORD1;
				float3 normal : NORMAL;
			};

			float2x2 rot(float a)
			{
				float s = sin(a), c = cos(a);
				return float2x2(c,s,-s,c);
			}

			float dist(float3 p)
			{
				/*
				for (int i = 0; i < 5; i++)
				{
					p.x = abs(p.x) - 1.0;
					p.xy = mul(rot(1.),p.xy);
					p.xz = mul(rot(1.), p.xz);
				}
				p = M(p,4);
				*/
				float s = length(p) - 0.3;
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
				o.screen = o.vertex;
				o.vertexW = mul(unity_ObjectToWorld,v.vertex);
				o.normal = v.normal;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//UNITY_UV_STARTS_AT_TOP,_ScreemParamsは
				//https://qiita.com/edo_m18/items/591925d7fc960d843afa
					#if UNITY_UV_STARTS_AT_TOP
								i.screen.y *= -1.0;
					#endif
					i.screen.x *= _ScreenParams.x / _ScreenParams.y;
					float2 p = i.screen.xy / i.screen.w;
					float3 cp = i.vertexW;
					float3 cd = -UNITY_MATRIX_V[2].xyz;
					float3 cu = UNITY_MATRIX_V[1].xyz;
					float3 cs = UNITY_MATRIX_V[0].xyz;

					//the Ray starting position when camera in object
					//カメラ方向と法線の内積の正負によってレイの開始位置を変えられます
					//外から見るだけならここは不要
					float sep = dot(i.normal, cd);
					cp = step(0, sep) * _WorldSpaceCameraPos
						+ step(sep, 0) * i.vertexW;
					//ここまで

					float target = abs(UNITY_MATRIX_P[1][1]);

					float3 rd = normalize(float3(p.x * cs + p.y * cu + target * cd));

					float depth = 0.;
					float3 normal = 0;
					float3 color = 0;
					for (int i = 0; i < 99; i++)
					{
						float3 rp = cp + rd * depth;
						float d = objDist(rp);
						if (d < DELTA)
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
