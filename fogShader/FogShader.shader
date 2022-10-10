Shader "Unlit/FogwithDepth"
{
    Properties
    {
        [HDR]_FogColor("Fog Color",color)=(1,1,1,1)
        _FogStart("Fog Start",float)=0
        _FogEnd("Fog End",float) = 10
        _Multiple("Multiply",float) = 1.
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="AlphaTest-1"}
        Cull Off
        ZTest Always
        ZWrite Off
        GrabPass{"_GrabTexFog"}
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
                float3 pos : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            //sampler2D _CameraDepthTexture;
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            sampler2D _GrabTexFog;
            float4 _FogColor;
            float _Multiple;

            float   _FogStart;
            float   _FogEnd;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeGrabScreenPos(o.vertex);
                o.pos = v.vertex;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            float3 random3(float3 c) {
                float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
                float3 r;
                r.z = frac(512.0*j);
                j *= .125;
                r.x = frac(512.0*j);
                j *= .125;
                r.y = frac(512.0*j);
                return r-0.5;
            }

            //https://www.shadertoy.com/view/XsX3zB
            /* skew constants for 3d simplex functions */
            const float F3 =  0.3333333;
            const float G3 =  0.1666667;
            
            /* 3d simplex noise */
            float simplex3d(float3 p) {
                /* 1. find current tetrahedron T and it's four vertices */
                /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
                /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
                
                /* calculate s and x */
                float3 s = floor(p + dot(p, float3(F3,F3,F3)));
                float3 x = p - s + dot(s, float3(G3,G3,G3));
                
                /* calculate i1 and i2 */
                float3 e = step(float3(0.,0.,0.), x - x.yzx);
                float3 i1 = e*(1.0 - e.zxy);
                float3 i2 = 1.0 - e.zxy*(1.0 - e);
                
                /* x1, x2, x3 */
                float3 x1 = x - i1 + G3;
                float3 x2 = x - i2 + 2.0*G3;
                float3 x3 = x - 1.0 + 3.0*G3;
                
                /* 2. find four surflets and store them in d */
                float4 w, d;
                
                /* calculate surflet weights */
                w.x = dot(x, x);
                w.y = dot(x1, x1);
                w.z = dot(x2, x2);
                w.w = dot(x3, x3);
                
                /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
                w = max(0.6 - w, 0.0);
                
                /* calculate surflet components */
                d.x = dot(random3(s), x);
                d.y = dot(random3(s + i1), x1);
                d.z = dot(random3(s + i2), x2);
                d.w = dot(random3(s + 1.0), x3);
                
                /* multiply d by w^4 */
                w *= w;
                w *= w;
                d *= w;
                
                /* 3. return the sum of the four surflets */
                return dot(d, float4(52.0,52.0,52.0,52.0));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv.xy/i.uv.w;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                float4 screenPos = float4(i.uv.xyz,i.uv.w + 0.000001 * 0.);
                float4 screenPosNorm = screenPos / screenPos.w;
                screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
                float eyeDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPosNorm.xy));
                float3 cameraViewDir = -UNITY_MATRIX_V._m20_m21_m22;
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 wpos = ((eyeDepth * worldViewDir * (1.0 / dot(cameraViewDir, worldViewDir))) + _WorldSpaceCameraPos);

                float3 cameraPos = _WorldSpaceCameraPos;
                float calDepth = length(wpos - cameraPos);
                //calDepth = saturate(sin(calDepth / 100.)-0.5);
                calDepth = (calDepth < _FogStart)?_FogStart:(calDepth > _FogEnd)?_FogEnd : calDepth;
                calDepth = calDepth / abs(_FogStart - _FogEnd);
                depth = calDepth;
                // float3 pos = wpos;
                // depth = Linear01Depth(depth);
                // //depth = eyeDepth;
                // depth = 1 - depth;
                // depth = saturate(depth * _Multiple);
                // //depth = (depth > 0.99)?0.:depth;
                
                float4 defaultCol = tex2D(_GrabTexFog,uv);
                float4 fogCol = _FogColor;

                //fogCol.rgb *= simplex3d(wpos);
                //float4 col = lerp(fogCol,defaultCol,depth);
                
                float4 col = lerp(defaultCol,fogCol,calDepth);

                //wpos *= 0.5;
                //col.rgb = pow(abs(cos(wpos.xyz * UNITY_PI * 4)), 20);
                //col = depth;
                //col.rgb = screenPosNorm;
                return col;
            }
            ENDCG
        }
    }
}
