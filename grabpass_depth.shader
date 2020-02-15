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
                return normalize(map(p).x - float3(map(p - e.xyy).x,map( p - e.yxy).x,map( p - e.yyx).x));
            }

            float marching(float3 ro,float3 rd)
            {
                float depth = 0.0;
                for(int i = 0 ; i< 99; i++)
                {
                    float3 rp = ro + rd * depth;
                    float2 d = map(rp);
					
					//if(MAXDEPTH < d.x + depth){break;}
                    if(abs(d.x) < 0.01)
                    {
                        return depth;
                    }
                    depth += d.x;
                }
                return -1;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.GUV.xy/i.GUV.w;
                float3 ro = i.ro;
				float3 rd = normalize(i.surf - ro);
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,uv);
				depth = LinearEyeDepth(depth);
				float3 gt = tex2D(_GrabTex,uv);
                float3 color = 0;
                float2 d = marching(ro,rd);
                if(d.x > 0)
                {
                    float3 light = normalize(float3(0.2,0.4,0.8));
                    color = 1;
                    float3 normal = calcNormal(ro + rd * d.x);
                    float diff = 0.5 + 0.5 * saturate(dot(light,normal));
                    color = color * diff;
                    color = normal;
                }
				d.x = (d.x < 0)?depth+1:d.x;
				color = lerp(gt,color,(d.x < depth) );
                return float4(color,1) ;
            }
            ENDCG
        }
    }
}
