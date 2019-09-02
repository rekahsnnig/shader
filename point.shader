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
			#include "light.cginc"

			
			ENDCG
		}
			GrabPass{ "_grabTex" }
		Pass
		{
			Tags { "RenderType" = "Opaque" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 uv : TEXCOORD1;
			};

			sampler2D _grabTex;
			float _Fineness;


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
				float3 cameraPos = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1)).xyz;
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
