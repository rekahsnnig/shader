Shader "Unlit/celler3D 1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                float4 vertexW : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.vertexW = v.vertex;
                return o;
            }
            
           float2 rand(float2 st)
            {
                st =float2(dot(st,float2(127.1, 311.7)),
                           dot(st,float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float3 rand(float3 st)
            {
                st =float3(dot(st,float2(127.1, 311.7)),
                           dot(st,float2(269.5, 183.3)),
                           dot(st,float2(109.7,434.1)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }
            
            float random2(float2 v){
                // https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
                return frac(sin(dot(v.xy, float2(12.9898,78.233))) * 43758.5453);
            }
            //https://glslfan.com/?channel=-L3YHd1kovws9UxeVcEc
            float random3(float3 v){
                v.x += v.z * 1.11111;
                return random2(v.xy);
            }

            float4 celler3D(float3 i,float3 sepc)
            {
                float3 sep = i * sepc;
                float3 fp = floor(sep);
                float3 sp = frac(sep);
                float dist = 5.;
                float3 mp = 0.;

                float3 op = float3(1.111,0.,0.);
                [unroll]
                for (int z = -1; z <= 1; z++)
                {
                    for (int y = -1; y <= 1; y++)
                    {
                        for (int x = -1; x <= 1; x++)
                        {
                            float3 neighbor = float3(x, y ,z);
                            float3 pos = float3(random3(fp+neighbor+op),random3(fp+neighbor+op.yxz),random3(fp+neighbor+op.zyx));
                            pos = sin(pos +_Time.y*pos)* 0.5 + 0.5;
                            float divs = length(neighbor + pos - sp);
                            mp = (dist >divs)?pos:mp;
                            dist = (dist > divs)?divs:dist;
                        }
                    }
                }
                return float4(mp,dist);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 celler = celler3D(i.vertexW.xyz,20);
                float3 col = length(celler.xyz*celler.xyz*celler.xyz)*(1-celler.w);
                return fixed4(col,1);
            }
            ENDCG
        }
    }
}
