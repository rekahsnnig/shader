Shader "Unlit/dddd"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off
        ZTest Always
        GrabPass{"_GrabTex"}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define MAXDEPTH 100.

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 ro :TEXCOORD0;
                float3 surf :TEXCOORD1;
                float4 GUV :TEXCOORD2;
            };

            sampler2D _CameraDepthTexture;
            sampler2D _GrabTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                o.ro = _WorldSpaceCameraPos;
                o.surf = v.vertex;
                o.surf = mul(unity_ObjectToWorld,v.vertex);
                o.GUV = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            float map(float3 p)
            {
                p = mul(unity_WorldToObject,float4(p,1));
                p += sin(p.zxy*100. + _Time.y)/100.;
                float s = length(p) - 0.3;
                return s;
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
                    
                    //if(MAXDEPTH < d.x + depth){break;}
                    if(abs(d) < 0.01)
                    {
                        return depth;
                    }
                    depth += d.x;
                }
                return -1;
            }
            
            float getdepth(float2 uv,float2 e)
            {
                float2 dx = ddx(uv) * e;
                float2 dy = ddy(uv) * e;
                float depth = tex2Dgrad(_CameraDepthTexture,uv,dx,dy);
                depth = LinearEyeDepth(depth);
                return depth;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.GUV.xy/i.GUV.w;
                float2 e = float2(0.,0.001);
                float3 N = normalize(getdepth(uv,e.xx) - float3(getdepth(uv + e,e),getdepth(uv + e.yx,e.yx),getdepth(uv - e,-e)));
                
                
                float3 color = N;
                return float4(color,1) ;
            }
            ENDCG
        }
    }
}
