Shader "MatCap"
{
    Properties
    {
        _MatCap ("Mat Cap", 2D) = "white" {}

        [Space(10)]
        [Toggle]_UseOnlyConfigurationH("Use only Hue in the configuration",float) = 0
        [Toggle]_UseOnlyConfigurationS("Use only Saturation in the configuration",float) = 0
        [Toggle]_UseOnlyConfigurationV("Use only Value in the configuration",float) = 0
        _HSV("HSV Color",color) = (0,0,0,0)
        [HDR]_Color("RGB Color multiply",color) = (1,1,1,1)

        [Space(10)]
        [Toggle]_ClampOn("Clamp",float) = 0
    }

    Subshader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MatCap;
            float _UseOnlyConfigurationH;
            float _UseOnlyConfigurationS;
            float _UseOnlyConfigurationV;
            float3 _HSV;
            float4 _Color;

            float _ClampOn;

            struct v2f
            {
                float4 pos  : SV_POSITION;
                half2 uv    : TEXCOORD0;
            };
            
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (v.vertex);
                float3 normal = UnityObjectToWorldNormal(v.normal);
                normal = mul((float3x3)UNITY_MATRIX_V, normal);
                o.uv = normal.xy * 0.5 + 0.5;

                return o;
            }
//https://glslsandbox.com/e#41371.0F
            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            float3 rgb2hsv(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }
            
            float4 frag (v2f i) : COLOR
            {
                float4 col = tex2D(_MatCap, i.uv);
                col.rgb = rgb2hsv(col.rgb);
                col.r = lerp(col.r,0,_UseOnlyConfigurationH);
                col.g = lerp(col.g,0,_UseOnlyConfigurationS);
                col.b = lerp(col.b,0,_UseOnlyConfigurationV);
                col.rgb += rgb2hsv(_HSV.xyz);
                col.rgb = hsv2rgb(col.rgb);
                col.rgb *= _Color;
                
                col.rgb = lerp(col.rgb,saturate(col.rgb),_ClampOn);
                return col;
            }

            ENDCG
        }
    }
}