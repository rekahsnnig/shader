Shader "Unlit/StendGrass3"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Scale("Scale",float) = 10.
    }
    SubShader
    {
        
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "LightMode"="ForwardBase"}
        GrabPass{"_GrabTex"}
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
                float3 normal : normal;
                float4 tangent : tangent;
            };

             struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 ouv :texcoord3;
                float3 pos : texcoord4;
                float3 normal : normal;
                half3 lightDir : TEXCOORD5;
                half3 viewDir : TEXCOORD6;
            };

            sampler2D _GrabTex;
            float4 _MainTex_ST;
            float _Scale;
            float4 _LightColor0;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = v.uv;
                o.uv = ComputeGrabScreenPos(o.vertex);
                o.ouv = v.uv;
                o.pos = v.vertex.xyz;
                o.normal = v.normal;

                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                return o;
            }

            float2 random22(float2 st)
            {
                st = float2(dot(st, float2(127.1, 311.7)),
                            dot(st, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float s;
            void srand(float2 p){
                s=sin(dot(p,float2(423.62431,321.54323)));
            }
            float rand(){
                s=frac(s*32322.65432+0.12333);
                return abs(frac(s));
            }
            float grad(float t){
                return 6.0*pow(t,5.0)-15.0*pow(t,4.0)+10.0*pow(t,3.0);
            }
            float2x2 rot(float a){return float2x2(cos(a),sin(a),-sin(a),cos(a));}

            float lPoly(float2 p,float n){
                float a = atan2(p.x,p.y)+UNITY_PI;
                float r = (UNITY_PI * 2.)/n;
                return cos(floor(.5+a/r)*r-a)*length(p)/cos(r*.5);
            }

            float3 celler2D(float2 i,float2 sepc)
            {
                float2 sep = i * sepc;
                float2 fp = floor(sep);
                float2 sp = frac(sep);
                float dist = 50.;
                float2 mp = 0.;
                
                float2 ccs = 0.;

                [unroll]
                for (int y = -1; y <= 1; y++)
                {
                    [unroll]
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 neighbor = float2(x, y);
                        float2 pos = float2(random22(fp+neighbor));
                        pos = sin(pos*6. +_Time.y/2.)* 0.5 + 0.5;
                        //pos += fp + pos;
                        //ccs += pos; 
                        float2 p = neighbor + pos - sp;
                        float divs = length(p);
                        divs = lPoly(p,3.);
                        mp = (dist  > divs)?pos:mp;
                        dist = (dist > divs)?divs:dist;
                    }
                }
                return float3(mp,dist);
            }

            float3 celler2D_returnUV(float2 i,float2 sepc)
            {
                float2 sep = i * sepc;
                float2 f = floor(sep);
                float dist = 5.;
                float2 ouv = float2(0.,0.);

                for (int y = -3; y <= 3; y++)
                {
                    for (int x = -3; x <= 3; x++)
                    {
                        float2 neighbor = float2(x, y );
                        srand(f + neighbor);
                        float2 o;
                        o.x = rand();
                        o.y = rand();
                       // o =mul( rot(t * (rand() - 0.1)),o);
                        float2 p = f + o + neighbor - sep;
                        float divs = length(p);
                      //  divs = lPoly(p,3.);
                      //  float divs = length(f + neighbor + o - sep);
                        if(divs < dist){
                            dist=divs;
                            ouv  = o + neighbor + f;
                        }
                    }
                }
                return float3(ouv,dist);
            }

            float3 random33(float3 st)
            {
                st = float3(dot(st, float3(127.1, 311.7,811.5)),
                            dot(st, float3(269.5, 183.3,211.91)),
                            dot(st, float3(511.3, 631.19,431.81))
                            );
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float4 celler3D_returnPos(float3 i,float3 sepc)
            {
                float3 sep = i * sepc;
                float3 fp = floor(sep);
                float3 sp = frac(sep);
                float dist = 5.;
                float3 mp = 0.;
                float3 opos = 0.;

                [unroll]
                for (int z = -1; z <= 1; z++)
                {
                    [unroll]
                    for (int y = -1; y <= 1; y++)
                    {
                        [unroll]
                        for (int x = -1; x <= 1; x++)
                        {
                            float3 neighbor = float3(x, y ,z);
                            float3 rpos = float3(random33(fp+neighbor));
                            float3 pos = sin( (rpos*6. +_Time.y/2.) )* 0.5 + 0.5;
                            float divs = length(neighbor + pos - sp);
                            if(dist > divs)
                            {
                                mp = pos;
                                dist = divs;
                                opos = neighbor + fp + rpos;
                            }
                        }
                    }
                }
                return float4(opos,dist);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv.xy/i.uv.w;
                float scale = _Scale;
                float2 ouv = i.ouv;
                float3 cell = celler2D_returnUV(ouv , (scale));
                uv = (cell.xy) / scale;

                
                float4 opos = celler3D_returnPos(i.pos,scale);
                opos /= scale;
                float4 grabUV = ComputeGrabScreenPos(UnityObjectToClipPos(float4(opos.xyz,1.)));
                float2 screenuv = grabUV.xy / grabUV.w;
                fixed4 col = tex2D(_GrabTex, screenuv) ;

                float3 ld = normalize(i.lightDir);
                float3 vd = normalize(i.viewDir);
                float3 halfDir = normalize(ld + vd);

                //i.normal.x += step(opos.z,.5);
                half4 diff = saturate(dot(i.normal, ld)) * _LightColor0;
                diff = lerp(diff,1.,.9);
                half3 sp = pow(max(0, dot(i.normal, halfDir)), 10. * 128.0) * col.rgb;

                col.rgb = diff * col.rgb + sp;
                //col.rgb += sp;
                return col;
            }
            ENDCG
        }
    }
}
