Shader "geometry/geomtry_boxel"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Size("Size",float) = 0.1
		
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
			#pragma geometry geom
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 normal :NORMAL;
			};

			struct v2g
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 normal :NORMAL;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 normal :NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Size;
			
			
			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = v.normal;
				return o;
			}
            static const float3 boxes[24] = {
					float3(0.5, -0.5, 0.5),
					float3(0.5, 0.5, 0.5),
					float3(-0.5, -0.5, 0.5),
					float3(-0.5, 0.5, 0.5),
					float3(-0.5, -0.5, -0.5),
					float3(-0.5, 0.5, -0.5),
					float3(0.5, -0.5, -0.5),
					float3(0.5, 0.5, -0.5),
					float3(-0.5, 0.5, -0.5),
					float3(-0.5, 0.5, 0.5),
					float3(0.5, 0.5, -0.5),
					float3(0.5, 0.5, 0.5),
					float3(0.5, -0.5, -0.5),
					float3(0.5, -0.5, 0.5),
					float3(-0.5, -0.5, -0.5),
					float3(-0.5, -0.5, 0.5),
					float3(0.5, -0.5, -0.5),
					float3(0.5, 0.5, -0.5),
					float3(0.5, -0.5, 0.5),
					float3(0.5, 0.5, 0.5),
					float3(-0.5, -0.5, 0.5),
					float3(-0.5, 0.5, 0.5),
					float3(-0.5, -0.5, -0.5),
					float3(-0.5, 0.5, -0.5)
            	};

			[maxvertexcount(72) ]
			 void geom(triangle v2g input[3], inout TriangleStream<g2f> OutputStream)
			{
				g2f v = (g2f)0;
				
				[unroll]
				for(int j = 0;j < 3;j++){
                    [unroll]
                    for(int k = 0; k < 6; k++)
                    {
                        [unroll]
                        for(int l = 0; l < 4 ; l++)
                        {
                            v.vertex = UnityObjectToClipPos(input[j].vertex + float4(boxes[k*4+l]*_Size,0));
                            v.uv = input[j].uv;
                            v.normal = input[j].normal;
                            OutputStream.Append(v);
                        }
				        OutputStream.RestartStrip();
                    }
				}
		    }
			
			fixed4 frag (g2f i) : SV_Target
			{
				fixed4 col = i.normal;
				return col;
			}
			ENDCG
		}
		
	}
}
