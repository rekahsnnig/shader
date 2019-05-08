Shader "Unlit/a_Line"
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "Parlin.cginc"
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _subTex;
            float _Line;
            float _Speed;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			float range(float2 xy){
				return sqrt(pow(xy.x,2)+pow(xy.y,2));
			}

			float distance(float2 xy1, float xy2){
				return sqrt(pow(xy1.x-xy2.x,2)-pow(xy1.x-xy2.x,2));
			}
            
            float PtoLdis(float propX,float propY,float2 XY){
               return abs(propX * XY.x + propY * XY.y)/sqrt(pow(propX,2) + pow(propY,2));
            }

			float theta (float2 xy){
				return atan(xy.y/xy.x);
			}
            
            

			fixed4 frag (v2f i) : SV_Target
			{
				float Theta = (_Speed * _Time.z)%360;
				float2x2 rotate = {
										float2(cos(Theta),-sin(Theta)),
										float2(sin(Theta),cos(Theta))
									};
				fixed4 col = tex2D(_MainTex, i.uv);
                //1 * sin(Theta) + 1 * cos(Theta)
				float2 UVpr = mul(rotate,float2(0.1,0.1));
                //lead linear function
                
               // col += (abs(PtoLdis(cos(Theta),sin(Theta),(i.uv - float2(0.5,0.5)) ))<_Line)?tex2D(_MainTex, i.uv):float4(0,0,0,0);
				col = (abs(PtoLdis(cos(Theta + fBm(i.uv + float2(0.1,0.1),4)),
								   sin(Theta + fBm(i.uv + float2(0.1,0.1),4)),
								  /*(i.uv - float2( 
												fBm( i.uv * float2(sin(Theta),cos(Theta) ),4),
												fBm( i.uv * float2(cos(Theta),sin(Theta) ),4) 
									)            )*/
									(i.uv - float2( 0.5,0.5) )
					   )  )       < (_Line*(i.uv + float2(0.1,0.1),1.5 * pow(sin(fBm(i.uv,4)*Theta%360),2) ) ) )?
				float4(fBm(i.uv + float2(0.1,0.1),4),fBm(i.uv - float2(0.5,0.1),4),fBm(i.uv * float2(0.1,0.5),4),1) * tex2D(_MainTex, i.uv):float4(0,0,0,0);
				//col += (theta(i.uv-float2(-5,-5))==Theta&&distance()<0.2)?tex2D(_MainTex, i.uv):float4(0,0,0,0);
				//col += ((i.uv.x - 0.5)>UVpr.x&&(i.uv.y - 0.5)>UVpr.y)?tex2D(_MainTex, i.uv):float4(0,0,0,0);
				//col *= ((i.uv.x - 0.5)<UVpr.x&&(i.uv.y - 0.5)<UVpr.y&&((i.uv.x-0.5)*(i.uv.y-0.5))>0)?tex2D(_MainTex, i.uv):1;
				//col *= (i.uv.x>0.47&&i.uv.x<0.53&&i.uv.y>0.47&&i.uv.y<0.53)?tex2D(_MainTex, i.uv):1;
				//col *= (i.uv.x==0.5&&i.uv.y==0.5)?tex2D(_MainTex, i.uv):1;
				// apply fog
				col+=col*4;
				return col;
			}
			ENDCG
		}
	}
}
