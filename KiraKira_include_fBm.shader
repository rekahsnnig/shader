Shader "Unlit/KiraKira_include_fBm"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_subTex("Texture", 2D) = "white" {}
        _Line("Line",Range(0,1))=0.1
        _Speed("Speed",float)=0.1
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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _subTex;
            float _Line;
            float _Speed;

			//-----------------------------------------------------------------------------------------
			//点と0=ax+byの直線の距離を求めて返してくれる関数
            float PtoLdis(float propX,float propY,float2 XY){
               return abs(propX * XY.x + propY * XY.y)/sqrt(pow(propX,2) + pow(propY,2));
            }

			fixed2 random2(fixed2 st){
				st = fixed2( dot(st,fixed2(127.1,311.7)),
							   dot(st,fixed2(269.5,183.3)) );
				return -1.0 + 2.0*frac(sin(st)*43758.5453123);
			}

			float perlinNoise(fixed2 st) 
			{
				fixed2 p = floor(st);
				fixed2 f = frac(st);
				fixed2 u = f*f*(3.0-2.0*f);

				float v00 = random2(p+fixed2(0,0));
				float v10 = random2(p+fixed2(1,0));
				float v01 = random2(p+fixed2(0,1));
				float v11 = random2(p+fixed2(1,1));

				return lerp( lerp( dot( v00, f - fixed2(0,0) ), dot( v10, f - fixed2(1,0) ), u.x ),
							 lerp( dot( v01, f - fixed2(0,1) ), dot( v11, f - fixed2(1,1) ), u.x ), 
							 u.y)+0.5f;
			}
            
			float fBm (fixed2 st,float octaves) 
			{
				float f = 0;
				fixed2 q = st;
				[unroll]
				for(int i = 1 ;i < octaves;i++){
					f += perlinNoise(q)/pow(2,i);
					q = q * (2.00+i/100);
				}

				return f;
			}
			//--------------------------------------------------------------------------------------------

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
            
            

			fixed4 frag (v2f i) : SV_Target
			{
				float Theta = (_Speed * _Time.z)%360;
				fixed4 col = tex2D(_MainTex, i.uv);
               //一つ目の回転
				col = (abs(PtoLdis(cos(Theta + fBm(i.uv + float2(0.1,0.1),4)),
								   sin(Theta + fBm(i.uv + float2(0.1,0.1),4)),
									(i.uv - float2( 0.5,0.5) )
					   )  )       < (_Line*(i.uv + float2(0.1,0.1),1.5 * pow(sin(fBm(i.uv,4)*100),2) ) ) )?
				float4(fBm(i.uv + float2(0.1,0.1),4),fBm(i.uv - float2(0.5,0.1),4),fBm(i.uv * float2(0.1,0.5),4),1) * tex2D(_MainTex, i.uv):float4(0,0,0,0);
                
                //２つ目の回転
                col += (abs(PtoLdis(cos(-Theta + fBm(i.uv*2 + float2(0.1,0.1),4)),
                                   sin(-Theta + fBm(i.uv*3 + float2(0.1,0.1),4)),
                                    (i.uv - float2( 0.5,0.5) )
                       )  )       < (_Line*(i.uv + float2(0.1,0.1),1.5 * pow(sin(fBm(i.uv*2,4)*100),2) ) ) )?
                float4(fBm(i.uv*3 + float2(0.1,0.1),4),fBm(i.uv*3 - float2(0.5,0.1),4),fBm(i.uv * float2(0.1,0.5),4),1) * tex2D(_subTex, i.uv):float4(0,0,0,0);
				col+=col*3;//色に加算　1を超えると光りだす
				return col;
			}
			ENDCG
		}
	}
}
