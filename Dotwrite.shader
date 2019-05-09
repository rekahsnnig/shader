Shader "Unlit/Dotwrite"
{
	Properties
	{
        _subTex("Texture", 2D) = "white" {}
        _Line("Line",Range(0,1))=0.1
        _Speed("Speed",float)=0.1
		_MainTex ("Texture", 2D) = "white" {}
        _Radius("Radius",Range(0,1)) = 0.5
        _Fine("Fine",float) = 5
        _Round("Round",range(0,1)) =0.5 
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
            float _Radius;
			float _Fine;
            float _Round;
            
            
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
            
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
            
            float RoundHis(float InColor){ //色成分の範囲を制限する
                return (_Round-0)/(1-0)*(InColor-0)+0;
            }
            
            //float His(float his){ //色成分の範囲を制限する
            //    return (_Round-0)/(1-0)*(InColor-0)+0;
            //}
			
			fixed4 frag (v2f i) : SV_Target
			{   
                float2 uv_lut;
                float pi = 3.141592;
                float Point = step(abs( sin((i.uv.x) * (_Fine * (pi))) ) * abs(sin((i.uv.y ) * (_Fine * (pi)))),sqrt(_Radius));//0.25にすると一つの円の半径をに０．５まで認めることになる
                //float circle = step(point,0); 
                uv_lut = i.uv;
                //float2 uv_lut = float2( ((i.uv)/_Fine)*_Fine);
                uv_lut = floor(uv_lut*_Fine )/_Fine;
                fixed4 col = tex2D(_MainTex, uv_lut);
               
                float Theta = (_Speed * _Time.z)%360;
                
                col += (abs(PtoLdis(cos(Theta + fBm(uv_lut + float2(0.1,0.1),4)),
                                   sin(Theta + fBm(uv_lut + float2(0.1,0.1),4)),
                                  /*(i.uv - float2( 
                                                fBm( i.uv * float2(sin(Theta),cos(Theta) ),4),
                                                fBm( i.uv * float2(cos(Theta),sin(Theta) ),4) 
                                    )            )*/
                                    (uv_lut - float2( 0.5,0.5) )
                       )  )       < (_Line*(uv_lut + float2(0.1,0.1),1.5 * pow(sin(fBm(uv_lut,4)*100),2) ) ) )?
                5 *float4(fBm(uv_lut + float2(0.1,0.1),4),fBm(uv_lut - float2(0.5,0.1),4),fBm(uv_lut * float2(0.1,0.5),4),1) * tex2D(_MainTex, uv_lut):float4(0,0,0,0);
                
                //２つ目の回転
                col += (abs(PtoLdis(cos(-Theta + fBm(uv_lut*2 + float2(0.1,0.1),4)),
                                   sin(-Theta + fBm(uv_lut*3 + float2(0.1,0.1),4)),
                                  /*(i.uv - float2( 
                                                fBm( i.uv * float2(sin(Theta),cos(Theta) ),4),
                                                fBm( i.uv * float2(cos(Theta),sin(Theta) ),4) 
                                    )            )*///中心位置動かすときは0.5をいじくる
                                    (uv_lut - float2( 0.5,0.5) )
                       )  )       < (_Line*(uv_lut + float2(0.1,0.1),1.5 * pow(sin(fBm(uv_lut*2,4)*100),2) ) ) )?
                 5 * float4(fBm(uv_lut*3 + float2(0.1,0.1),4),fBm(uv_lut*3 - float2(0.5,0.1),4),fBm(uv_lut * float2(0.1,0.5),4),1) * tex2D(_subTex, uv_lut):float4(0,0,0,0);
               
              //  col+=3 * col;
                col = float4(RoundHis(col.r),col.g,RoundHis(col.b),1) * (1 - Point);
				return col;
			}
			ENDCG
		}
	}
}
