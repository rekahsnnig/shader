Shader "Unlit/OBJSPC_raymarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 ro :TEXCOORD0;
                float3 surf :TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                o.surf = v.vertex;
                return o;
            }

            float map(float3 p)
            {
                return length(p) - 0.5;
            }

            float3 calcNormal(float3 p)
            {
                float2 e = float2(0.001,0.);
                return normalize(map(p) - float3(map(p - e.xyy),map( p - e.yxy),map( p - e.yyx)));
            }

            float marching(float3 ro,float3 rd)
            {
                float depth = 0.0;
                for(int i = 0 ; i< 99; i++)
                {
                    float3 rp = ro + rd * depth;
                    float d = map(rp);
                    if(d < 0.001)
                    {
                        return depth;
                    }
                    depth += d;
                }
                return -1;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 ro = i.ro;
                float3 rd = normalize(i.surf - ro);

                float3 color = 0;
                float d = marching(ro,rd);
                if(d > 0)
                {
                    float3 light = normalize(float3(0.2,0.4,0.8));
                    color = 1;
                    float3 normal = calcNormal(ro + rd * d);
                    float diff = 0.5 + 0.5 * saturate(dot(light,normal));
                    color = color * diff;
                   // color = normal;
                }
                return float4(color,1);
            }
            ENDCG
        }
    }
}
