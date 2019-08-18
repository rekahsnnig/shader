Shader "Unlit/Dotted3"
{

//http://haru-android.hatenablog.com/entry/2017/12/20/214146
	Properties
	{
        _RedStep("Red Step",Range(0,255)) = 2
        _GreenStep("Green Step",Range(0,255)) = 3
        _BlueStep("Blue Step",Range(0,255)) = 3
        [Space]
        _contrastIcs("influences Contrast",float) = 1
        _contrastIe("influence Contrast",float) = 1
        _HistgramIN_max("in max",range(0,1)) = 1
        _HistgramIN_min("in min",range(0,1)) = 0
        _HistgramOUT_max("out max",range(0,1)) = 1
        _HistgramOUT_min("out min",range(0,1)) = 0
        
        [Space(2)]
        
        _pointA("ToneCurve pointA",float)= 62
        _pointB("ToneCurve pointB",float)= 127
        _pointC("ToneCurve pointC",float)= 192
        _subTex("Texture", 2D) = "white" {}
		_MainTex ("Texture", 2D) = "black" {}
        _RedRound("red",Range(0,1))=1
         _BlueRound("blue",Range(0,1))=1
        _GreenRound("green",Range(0,1))=1
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
        Tags{ "RenderType" = "Transparent+1" "Queue" = "Transparent+1" }
        
        GrabPass{"_grabTex01"}
        LOD 100
        ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            
            sampler2D _grabTex01;
            //sampler2D _MainTex;
            //float4 _MainTex_ST;
            float4 _grabTex01_ST;
            
            float _RedStep;
            float _GreenStep;
            float _BlueStep;
            
            
            float _contrastIcs;
            float _contrastIe;
            float _HistgramIN_max;
            float _HistgramIN_min;
            float _HistgramOUT_max;
            float _HistgramOUT_min;

            float _pointA;
            float _pointB;
            float _pointC;
            
            float toneCurve(float x){
                x = 1*((_HistgramOUT_max-_HistgramOUT_min)/(_HistgramIN_max-_HistgramIN_min)*(x-_HistgramIN_min))+_HistgramOUT_min;
                //150:50-> 255:0 g=(255-0)/(150-0)*(f-50)+0
                x *= 255;
                float y = _contrastIcs +( _contrastIe * (x -127))+127;
                return clamp(y/255,0,1);
            }
            
            //前色合わせてnにする
            float3 poster3(float3 col){
                float3 outCol;
                
                //col *= 255;
               // float outCol = floor((col/floor(_Step)))/floor(_Step);
                //return clamp(outCol/255,0,1);
                //
                col *= 255;
               outCol.r = floor(((col.r - 0) / 255 - 0) * (_RedStep - 0));
			outCol.g = floor(((col.g - 0) / 255 - 0) * (_GreenStep - 0));
			outCol.b = floor(((col.b - 0) / 255 - 0) * (_BlueStep - 0));
		return outCol;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeGrabScreenPos(o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 in_uv = float2(i.uv.x / i.uv.w, i.uv.y / i.uv.w);
                fixed4 col = tex2D(_grabTex01, in_uv);
                //col = floor((col*255)/_Step)/_Step;
                col = float4(poster3(col.rgb),1);
                col = float4(toneCurve(col.r),toneCurve(col.g),toneCurve(col.b),1);
                return col+col*col;
            }
            ENDCG
         }
               
        GrabPass{ "grab_tex" }

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
                float4 grabPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D grab_tex; 
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
            
            //************************************************************************************************************
            float PtoLdis(float propX,float propY,float2 XY){
               return abs(propX * XY.x + propY * XY.y)/sqrt(pow(propX,2) + pow(propY,2));
            }
            
            float RoundHis(float InColor,float Round){ //色成分の範囲を制限する
                return (Round-0)/(1-0)*(InColor-0)+0;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = (1.0,1.0,1.0,1.0);
               // float2 uv_lut = i.uv;
                float2 uv_lut = float2(i.grabPos.x / i.grabPos.w, i.grabPos.y / i.grabPos.w);;
                float Point = 0;
                if(_DOT==1)
                {
                    float pi = 3.141592;

                    Point = step( float(abs( sin((uv_lut.x ) * (_Fine * (pi)/_Xlambda)) ) 
                                  * abs( sin((uv_lut.y ) * (_Fine * (pi)/_Ylambda))) ),sqrt(_Radius));//0.25にすると一つの円の半径を0.5まで認めることになる
                    
                    col = col * (1-Point);
                    
                    uv_lut = float2(floor(uv_lut.x * _Fine / _Xlambda)/(_Fine / _Xlambda),
                                    floor(uv_lut.y * _Fine / _Ylambda)/(_Fine / _Ylambda));
                }
                
               col *= tex2D(grab_tex, uv_lut);
               col =  float4(RoundHis(col.r,_RedRound),RoundHis(col.g,_GreenRound),RoundHis(col.b,_BlueRound),col.a);
               col =col*_EmissionPower;
               // col += float4(0.5,0.5,0.5,1);
               return col;
            }
            ENDCG
        }
    }
}
//tonoshake
