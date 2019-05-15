Shader "Unlit/Laplacian"
{
    Properties
    {
         _Fine("Fine",float) = 5
    }
    SubShader
    {
        Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
        
        GrabPass{"_grabTex"}
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
            
            float Sq_distanse(float2 IN,float2 dotpos,float offset)
            {
                //オフセットを引数として渡している　それを加算して適した位置に原点を持ってくる
                IN += offset; 
                dotpos += offset;
                //四角形の関数で入力されたUV座標の点がどれだけの大きさの四角形の輪郭にのっているかを出す
                float indis = abs(IN.x + IN.y)+abs(IN.x - IN.y); 
                float uv_dotdis = abs(dotpos.x + dotpos.y)+abs(dotpos.x - dotpos.y);
                //一ドットを九つに区切ったものが入力されているが、果たしてこの入力点はどこに属するものなのかって　見る
                return step(indis,uv_dotdis);
            }            
            float sum3x3(float3x3 col,float3x3 dis){ //入力された行列の全要素をかけて足す
               return col._m00 * dis._m00 + 
                      col._m01 * dis._m01 + 
                      col._m02 * dis._m02 + 
                      col._m10 * dis._m10 + 
                      col._m11 * dis._m11 + 
                      col._m12 * dis._m12 + 
                      col._m20 * dis._m20 + 
                      col._m21 * dis._m21 + 
                      col._m22 * dis._m22;
            }
            
            float sum_sum3x3(float3x3 col){ //入力された行列の全要素をかけて足す
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
                float2 grab_uv = float2(floor(in_uv * _Fine)/_Fine);
                in_uv -= grab_uv;      //位置合わせ
                float pix = 1/_Fine; //どれだけの幅を1pixelとみなすか
                float pi = 3.141592;
                
                float Point = step( float(abs( sin((grab_uv.x ) * (_Fine * (pi))) ) 
                                   * abs( sin((grab_uv.y ) * (_Fine * (pi)))) ),sqrt(0));//0.25にすると一つの円の半径を0.5まで認めることになる
                

                float3x3 Laplacian4 = float3x3(0,1,0,1,-4,1,0,1,0);//四近傍
                float3x3 Laplacian8 = float3x3(1,1,1,1,-8,1,1,1,1);//八近傍

                float3x3 Laplas = Laplacian4;//今は四近傍を使用中
                
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
                //全要素にstep(点,辺の長さ)をかけて全部加算
                //ある点がある四角から遠いのであればstep()は0を返す
                //step() * COLOR stepが0のときにこれを足したとしても値は増えない　結果的にその点が所属している四角形の中心の点の色だけ残る
                float3x3 red_mul = mul(Laplas,red);
                float3x3 green_mul = mul(Laplas,green);
                float3x3 blue_mul = mul(Laplas,blue);
                
                //計算しやすいように距離だけまとめて行列にしておく
                 float3x3 dist = float3x3(Sq_distanse(in_uv,grab_uv,a_uv),Sq_distanse(in_uv,grab_uv,b_uv),Sq_distanse(in_uv,grab_uv,c_uv),
                                          Sq_distanse(in_uv,grab_uv,d_uv),Sq_distanse(in_uv,grab_uv,e_uv),Sq_distanse(in_uv,grab_uv,f_uv),
                                          Sq_distanse(in_uv,grab_uv,g_uv),Sq_distanse(in_uv,grab_uv,h_uv),Sq_distanse(in_uv,grab_uv,i_uv)
                                          );
                //色要素ごとにラプラシアンフィルタをかけていく
                 col.r = sum_sum3x3(red_mul);
                 col.g = sum_sum3x3(green_mul);
                 col.b = sum_sum3x3(blue_mul);
                 //アルファ値はなんとなく平均をとってみた
                 col.a = ((col.r + col.g + col.b) /3);
                
                //なんか色が薄かったので10倍加算して光るようにした　アルファ値は変わらないように0を入れてある
                col += float4(col.xyz * 10,0);
                // col.r += (1-col.r)* e.r; //eはそのままの値
                // col.g += (1-col.g)* e.g;
                // col.b += (1-col.b)* e.b;
                return col;
            }
            ENDCG
        }
    }
}

