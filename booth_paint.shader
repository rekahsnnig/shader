Shader "Unlit/booth"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			

				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "AutoLight.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float4 vertexW : TEXCOORD1;
			};

			fixed2 random2(fixed2 st) {
				st = fixed2(dot(st, fixed2(127.1, 311.7)),
					dot(st, fixed2(269.5, 183.3)));
				return -1.0 + 2.0*frac(sin(st)*43758.5453123);
			}

			float perlinNoise(fixed2 st)
			{
				fixed2 p = floor(st);
				fixed2 f = frac(st);
				fixed2 u = f * f*(3.0 - 2.0*f);

				float v00 = random2(p + fixed2(0, 0));
				float v10 = random2(p + fixed2(1, 0));
				float v01 = random2(p + fixed2(0, 1));
				float v11 = random2(p + fixed2(1, 1));

				return lerp(lerp(dot(v00, f - fixed2(0, 0)), dot(v10, f - fixed2(1, 0)), u.x),
					lerp(dot(v01, f - fixed2(0, 1)), dot(v11, f - fixed2(1, 1)), u.x),
					u.y) + 0.5f;
			}

			float fBm(fixed2 st, float octaves)
			{
				float f = 0;
				fixed2 q = st;
				[unroll]
				for (int i = 1;i < octaves;i++) {
					f += perlinNoise(q) / pow(2, i);
					q = q * (2.00 + i / 100);
				}

				return f;
			}

			float3 poster3(float3 col,float3 steps) {

				float3 outCol;
				float RedStep = steps.r;
				float GreenStep = steps.g;
				float BlueStep = steps.b;


				col *= 255;

				outCol.r = floor((col.r) / floor(RedStep))*floor(RedStep);
				outCol.g = floor((col.g) / floor(GreenStep))*floor(GreenStep);
				outCol.b = floor((col.b) / floor(BlueStep))*floor(BlueStep);

				outCol.r = floor( ( (col.r - 0)/255 - 0 ) * (RedStep - 0) );
				outCol.g = floor(((col.g - 0) / 255 - 0) * (GreenStep - 0));
				outCol.b = floor(((col.b - 0) / 255 - 0) * (BlueStep - 0));
				return outCol;

			}

			float2 rot(float2 uv,float angle)
			{
				float2x2 mat = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
				return mul(mat,uv);
			}

			float3 woodColor(float2 uv)
			{
				float2 uv_edt = uv * 100;
				uv_edt *= float2(5,1);
				float noise = fBm(uv_edt,4);
				float3 col = float3(1, 0.5, 0.2) * noise;
				return col;
			}

			float3 tsutaColor(float2 uv)
			{
				float2 uv_edt = uv * float2(10,20);
				uv_edt = rot(uv_edt, _Time.x);
					uv_edt = uv_edt * 60 * abs(sin(fBm(uv, 3)));
				float noise =max(fBm(uv,1),fBm(uv_edt, 4) );
				float3 col = float3(0.2,0.5,.3) * noise;


				float3 step = float3(10,10,10);
				step.rb *= lerp(1,sin(_Time.yy/3.141592),abs(sin(_Time.x)));
				col = poster3(col,step);
				col += float3(col.r, -0.5, col.b);

				float3 decol = float3(0.2, 0.5, .3) * fBm(uv * 50, 1);

				col = lerp(decol,col,abs(sin(_Time.x)));
				return col;
			}

			float3 potColor(float2 uv)
			{
				float2 uv_edt = uv * 100;
				float3 col = float3(1, 0, 0);
				col *= fBm(uv.xx,2);
				col *= fBm(uv_edt,4);
				return col;
			}

			float3 dirtColor(float2 uv)
			{
				float2 uv_edt = uv * 100;
				float3 col = float3(1, 0.2, 0);
				col *= fBm(uv_edt, 4);
				return col;
			}

			float3 Diffuse(float3 color,float3 normal)
			{
				normal = normalize(normal);
				float3 light = normalize(_WorldSpaceLightPos0.xyz);

				light = float3(0,-0.5,1);

				float diffuse = saturate(  normalize( dot(normal,light) ) );
				diffuse = pow(diffuse * 0.5 + 0.5,2);
				return color * diffuse;
			}

			float3 reflection(v2f i, float3 col, float3 SpecularCol, float Shiness)
			{
					UNITY_LIGHT_ATTENUATION(attenuation, i, i.vertexW)
					float3 view = normalize(_WorldSpaceCameraPos - i.vertexW);
					float3 normal = normalize(i.normal);
					float3 light = normalize((_WorldSpaceLightPos0.w == 0) ? _WorldSpaceLightPos0.xyz : _WorldSpaceLightPos0 - i.vertexW);
					light = float3(-1, -0.5, 1);
					//directional light
					float3 rflt = normalize(reflect(-light, normal));
					//反射光ベクトルを検出し正規化している
					float diffuse = saturate(dot(normal, light));
					float specular = pow(saturate(dot(view, rflt)), Shiness);
					float3 ambient = ShadeSH9(half4(normal, 1));
					fixed3 color = diffuse * col * _LightColor0
						+ specular * SpecularCol * _LightColor0;
					color += ambient * col;
					return color;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normal = v.normal;
				o.vertexW = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float tsuta = step(0.4,i.uv.x) * step(i.uv.y,0.35);
				float wood = step( i.uv.x,0.4) * step(0,i.uv.y);
				float metal = step(0.7,i.uv.x) * step(0.3, i.uv.y)* step(i.uv.y,0.75);
				float pot = step(i.uv.x,0.8) * step(0.4,i.uv.x) * step(0.7,i.uv.y);
				float cushion = step(0.8,i.uv.x) * step(0.7,i.uv.y);
				float dirt = 1 - step( 1,tsuta + wood + metal + pot + cushion);
				
				float3 specularCol = float3(1, 1, 1);
				float3 roughSpecularCol = float3(1,0.5,0.5);

				float4 col = float4(0,0,0,1);
				float3 woodCol = wood * woodColor(i.uv);
				woodCol = wood * reflection(i, woodCol.rgb, specularCol, 4);

				float3 metalCol = float3(0.5,0.5,0.5);
				metalCol = metal * reflection(i, metalCol.rgb, specularCol, 10);

				float3 tsutaCol = tsutaColor(i.uv);
				tsutaCol = tsuta * reflection(i, tsutaCol, pow(tsutaCol,2), 10);

				float3 potCol = potColor(i.uv);
				potCol = pot * reflection(i, potCol.rgb, roughSpecularCol, 4);

				float3 dirtCol = dirt * dirtColor(i.uv);

				float3 cushionCol = float3(0,0,0);
				cushionCol = cushionCol * reflection(i, cushionCol, specularCol, 2);

				col.rgb += woodCol + tsutaCol + metalCol + potCol + dirtCol + cushionCol;
				col.rgb = Diffuse(col.rgb, i.normal);
				//col.rgb = reflection(i,col.rgb,specularCol,10);
				return col;
			}
			ENDCG
		}
	}
}
