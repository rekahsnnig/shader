Shader "Unlit/FogwithDepth"
{
    Properties
    {
        [HDR]_FogColor("Fog Color",color)=(1,1,1,1)
        _FogStart("Fog Start",float)=0
        _FogEnd("Fog End",float) = 10
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
                calDepth = (calDepth < _FogStart)?_FogStart:(calDepth > _FogEnd)?_FogEnd : calDepth;
                calDepth = calDepth / abs(_FogStart - _FogEnd);
                depth = calDepth;
                
                
                float4 defaultCol = tex2D(_GrabTexFog,uv);
                float4 fogCol = _FogColor;

                float4 col = lerp(defaultCol,fogCol,calDepth);

                return col;
            }
            ENDCG
        }
    }
}
