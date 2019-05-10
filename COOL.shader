Shader "Unlit/COOL"
{
	Properties
	{
        _subTex("Texture", 2D) = "white" {}
		_MainTex ("Texture", 2D) = "black" {}
        _RedRound("red",Range(0,1))=1
         _BlueRound("blue",Range(0,1))=1
        _GreenRound("green",Range(0,1))=1
        [Space]
        [Toggle]_LINE("Use line",float)=0
        _Line("Line",Range(0,1))=0.1
        _Speed("Speed",float)=0.1
        [Space]
        [Toggle]_DOT("Use Dot",float)=0
        _Xlambda("Xlambda",range(0.01,1)) = 1
        _Ylambda("Ylambda",range(0.01,1)) = 1
        _Radius("Radius",Range(0,1)) = 0.5
        _Fine("Fine",float) = 5
        _EmissionPower("Emission Power",float) = 1
        
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
        Cull off
        
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma shader_feature DOT
            #pragma shader_feature BEEM
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
            float _Radius;
			float _Fine;
            float _Round;
            float _EmissionPower;
            
            float _Xlambda;
            float _Ylambda;
            
            float _RedRound;
            float _BlueRound;
            float _GreenRound;
            
            float _LINE;
            float _DOT;
            
 //************************************************************************************************************
            //http://nn-hokuson.hatenablog.com/entry/2017/01/27/195659#fBmノイズ
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
            
            float PtoLdis(float propX,float propY,float2 XY){
               return abs(propX * XY.x + propY * XY.y)/sqrt(pow(propX,2) + pow(propY,2));
            }
            
            
            
            float RoundHis(float InColor,float Round){ //色成分の範囲を制限する
                return (Round-0)/(1-0)*(InColor-0)+0;
            }
 //************************************************************************************************************
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
            
			fixed4 frag (v2f i) : SV_Target
			{
                float2 uv_lut = i.uv;
                if(_DOT==1)
                {
                    float pi = 3.141592;
                    float Point = step( abs( sin((i.uv.x) * (_Fine * (pi)/_Xlambda)) ) * abs(sin((i.uv.y ) * (_Fine * (pi)/_Ylambda))),sqrt(_Radius));//0.25にすると一つの円の半径を0.5まで認めることになる
                    if((1-Point)==0){discard;}
                        
                    uv_lut = float2(floor(i.uv.x*_Fine / _Xlambda)/(_Fine / _Xlambda),
                                    floor(i.uv.y*_Fine / _Ylambda)/(_Fine / _Ylambda));
                }
                
                fixed4 col = tex2D(_MainTex, uv_lut);
                
                if(_LINE==1)
                {
                    float Theta = (_Speed * _Time.z)%360;
                        
                    float beem01 = abs(PtoLdis(cos(Theta + fBm(uv_lut + float2(0.1,0.1),4)),
                                                   sin(Theta + fBm(uv_lut + float2(0.1,0.1),4)),
                                                   (uv_lut - float2( 0.5,0.5) )
                                          )        );
                    float beem02 = abs(PtoLdis(cos(-Theta + fBm(uv_lut*2 + float2(0.1,0.1),4)),
                                                   sin(-Theta + fBm(uv_lut*3 + float2(0.1,0.1),4)),
                                                   (uv_lut - float2( 0.5,0.5) )
                                          )        );
                                          
                    float lineWidth01 = _Line*(uv_lut + float2(0.1,0.1),1.5 * pow(sin(fBm(uv_lut,4)*100),2) );
                    float lineWidth02 = _Line*(uv_lut + float2(0.1,0.1),1.5 * pow(sin(fBm(uv_lut*2,4)*100),2) );
                        
                        //ここの色は適当
                    float4 beemColor01 = 5 * float4(fBm(uv_lut + float2(0.1,0.1),4),fBm(uv_lut - float2(0.5,0.1),4),fBm(uv_lut * float2(0.1,0.5),4),1) * tex2D(_MainTex, uv_lut);
                    float4 beemColor02 = 5 * float4(fBm(uv_lut*3 + float2(0.1,0.1),4),fBm(uv_lut*3 - float2(0.5,0.1),4),fBm(uv_lut * float2(0.1,0.5),4),1) * tex2D(_subTex, uv_lut);
                        
                    col += step(lineWidth01,beem01) * beemColor01;
                    col += step(lineWidth01,beem02) * beemColor02;    
                }
                col =  float4(RoundHis(col.r,_RedRound),RoundHis(col.g,_GreenRound),RoundHis(col.b,_BlueRound),1);
                col =col*_EmissionPower;
				return col;
			}
			ENDCG
		}
	}
   
}
