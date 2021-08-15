Shader "Unlit/special_filter3x3"
{
    Properties
    {
         _Fine("Fine",float) = 500
         _Coefficient("Coefficient",float) = 1
         _One("One",vector)=(1,1,1)
         _Two("Two",vector)=(1,-8,1)
         _Three("Three",vector)=(1,1,1)
         [Space(2)]
         _times("times",float) = 1
         
    }
    SubShader
    {
        Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
        
        GrabPass{"_grabTex"}
        ZTest Always
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
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _grabTex;
            //sampler2D _MainTex;
            //float4 _MainTex_ST;
            float4 _grabTex_ST;
            float _Fine;
            
            float _Coefficient;
            
            float3 _One;
            float3 _Two;
            float3 _Three;
            float _times;
            
            float sum_sum3x3(float3x3 col){ //入力された行列の全要素を足す
               return col._m00 + 
                      col._m01 + 
                      col._m02 + 
                      col._m10 + 
                      col._m11 + 
                      col._m12 + 
                      col._m20 + 
                      col._m21 + 
                      col._m22 ;
            }
            
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeGrabScreenPos(o.vertex);
                return o;
            }
            
            fixed4 frag (v2f IN) : SV_Target
            {
                fixed4 col;
                
                float2 in_uv = float2(IN.uv.x / IN.uv.w, IN.uv.y / IN.uv.w);
                //座標を_Fineの値に応じて粗くする->ドット調になる
                //lut
                float2 grab_uv = float2(floor(in_uv * _Fine)/_Fine);
                float pix = 1/_Fine; //どれだけの幅を1pixelとみなすか
                float pi = 3.141592;
                
                //係数をかけつつFilterの要素を合わせて3x3のフィルタを作る
                float3x3 Filter3x3 = _Coefficient * float3x3(_One,_Two,_Three);
                
                //九つの上一列
                //〇〇〇
                //------
                //------
                float2 a_uv = float2(-pix,-pix);
                float2 b_uv = float2(0,-pix);
                float2 c_uv = float2(+pix,-pix);

                //九つの真ん中一列
                //------
                //〇〇〇
                //------
                float2 d_uv = float2(-pix,0);
                float2 e_uv = float2(0,0);
                float2 f_uv = float2(+pix,0);

                //九つの一番下一列
                //------
                //------
                //〇〇〇
                float2 g_uv = float2(-pix,+pix);
                float2 h_uv = float2(0,+pix);
                float2 i_uv = float2(+pix,+pix);

                //それぞれの中心点の色
                fixed4 a = tex2D(_grabTex, grab_uv+a_uv);
                fixed4 b = tex2D(_grabTex, grab_uv+b_uv);
                fixed4 c = tex2D(_grabTex, grab_uv+c_uv);
                
                fixed4 d = tex2D(_grabTex,grab_uv+d_uv);
                fixed4 e = tex2D(_grabTex,grab_uv+e_uv);
                fixed4 f = tex2D(_grabTex,grab_uv+f_uv);
               
                fixed4 g = tex2D(_grabTex,grab_uv+g_uv);
                fixed4 h = tex2D(_grabTex,grab_uv+h_uv);
                fixed4 i = tex2D(_grabTex,grab_uv+i_uv);
                
                //色成分ごとに3x3行列を作る
                float3x3 red =   float3x3(a.r, b.r, c.r, d.r , e.r, f.r, g.r, h.r, i.r);
                float3x3 green = float3x3(a.g, b.g, c.g, d.g , e.g, f.g, g.g, h.g, i.g);
                float3x3 blue =  float3x3(a.b, b.b, c.b, d.b , e.b, f.b, g.b, h.b, i.b);
                
                //色要素ごとにフィルタをかけていく
                float3x3 red_mul = mul(Filter3x3,red);
                float3x3 green_mul = mul(Filter3x3,green);
                float3x3 blue_mul = mul(Filter3x3,blue);
                
                
                 col.r = sum_sum3x3(red_mul);
                 col.g = sum_sum3x3(green_mul);
                 col.b = sum_sum3x3(blue_mul);
                 col.a = ((col.r + col.g + col.b) /3);
                
                col += float4(col.xyz * 10,0) * _times;
                return col;
            }
            ENDCG
        }
    }
}
