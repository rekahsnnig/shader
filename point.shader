Shader "shader/point"
{
	Properties
	{
		_Fineness("Fineness",float) = 75
		_MainTex("Texture", 2D) = "black" {}
		_SpecularTex("Specular Texture", 2D) = "white" {}
		[HDR]_SpecularColor("Specular color", Color) = (1,1,1,1)
		[Header(Parameters)]_Shiness("Shiness",float) = 0.72
		_ratio("ratio",range(0,1)) = 0.66
		_Extremeness("Extremeness",float) = 20
	}
	SubShader
	{
		
		LOD 100
		Cull off
		Pass
		{
			Tags { "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
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

			float4 _SpecularColor;
			float _Shiness;
			float _ratio;
			float _Threshold;
			float _Extremeness;

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _SpecularTex;

			float3 Diffuse(float3 color,float3 normal)
			{
				normal = normalize(normal);
				float3 light = normalize(_WorldSpaceLightPos0.xyz);

				//light = float3(0,-0.5,1);

				float diffuse = saturate(normalize(dot(normal,light)));
				diffuse = pow(diffuse * 0.5 + 0.5,2);
				return color * diffuse;
			}

			float3 reflection(float4 vertexW,float3 in_normal, float3 col, float3 SpecularCol, float Shiness)
			{
					float3 view = normalize(_WorldSpaceCameraPos - vertexW);
					float3 normal = normalize(in_normal);
					float3 light = normalize((_WorldSpaceLightPos0.w == 0) ? _WorldSpaceLightPos0.xyz : _WorldSpaceLightPos0 - vertexW);

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



			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normal = v.normal;
				o.vertexW = v.vertex;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 specularCol = _SpecularColor * tex2D(_SpecularTex, i.uv);
				float shiness = _Shiness;
				fixed4 texCol = tex2D(_MainTex, i.uv);
				float4 col = texCol;
				//col.rgb = Diffuse(col.rgb, i.normal);
				col.rgb = reflection(i.vertexW,i.normal,col.rgb,specularCol,shiness);
				col.rgb = pow(col.rgb, _Extremeness);
				col = lerp(texCol,col,_ratio);
				return col;
			}
			ENDCG
		}
			GrabPass{ "_grabTex" }
		Pass
		{
			Tags { "LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 uv : TEXCOORD1;
			};

			sampler2D _grabTex;
			float _Fineness;
			float _ratio;


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = ComputeGrabScreenPos(o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float Fine = _Fineness;
				float2 uv = float2(i.uv.x / i.uv.w, i.uv.y / i.uv.w);
				//vertexW = float3(0, 0, 0);
				float3 cameraPos = mul(float4(_WorldSpaceCameraPos,1), UNITY_MATRIX_MV);
				float distance = length(cameraPos);
				Fine *= distance;

				uv = float2(floor(uv.x*Fine) / (Fine),
									floor(uv.y*Fine) / (Fine));
				fixed4 textureColor = tex2D(_grabTex, uv);
				return textureColor;
			}

			ENDCG
		}
	}
}
