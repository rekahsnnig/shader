Shader "Custom/base-MatCap"
{
    Properties
    {
        _NormalMap("normal map",2D) ="white"{}
        _NormalMapTiling("normal map tiling",vector) =(0,0,0,0)
        _StrengthOfNormalMap("Strength of NormalMap",range(0,1)) = 0
        [Space(20)]
        _MatCap0 ("Mat Cap0", 2D) = "white" {}
       // _TargetVertexColor0("Target Vertex Color",vector) = (0,0,0,0)
        [Space(20)]
        _MatCap1 ("Mat Cap1", 2D) = "white" {}
      //  _TargetVertexColor1("Target Vertex Color",vector) = (0,0,0,0)
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

            sampler2D _NormalMap;
            float4 _NormalMapTiling;
            sampler2D _MatCap0;
            float3 _TargetVertexColor0;
            sampler2D _MatCap1;
            float3 _TargetVertexColor1;

            float  _StrengthOfNormalMap;

            struct appdata
            {
                float4 vertex       : POSITION;
                half3 normal        : NORMAL;
                half4 tangent       : TANGENT;
                float3 color : COLOR;
                float2 uv : TEXCOORD0;
            };
                
            struct v2f
            {
                float4 pos  : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 vcol : COLOR;

                half3 tanNormal        : TEXCOORD2;
                half4 tangent       : TEXCOORD3;
                half3 binormal      : TEXCOORD4;
            };
                
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.vcol = v.color;

                o.binormal      = normalize(cross(v.normal.xyz, v.tangent.xyz) * v.tangent.w * unity_WorldTransformParams.w);
                o.tanNormal        = UnityObjectToWorldNormal(v.normal);
                o.tangent       = mul(unity_ObjectToWorld, v.tangent.xyz);
                o.binormal      = mul(unity_ObjectToWorld, o.binormal);
                return o;
            }
                
            float4 frag (v2f i) : COLOR
            {   
                float3 normal = UnityObjectToWorldNormal(i.normal);
                normal = mul((float3x3)UNITY_MATRIX_V, normal);

                float3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv));

                //toWorldNormal
                normalMap = (i.tangent * normalMap.x) 
                            + (i.binormal * normalMap.y)
                            + (i.tanNormal * normalMap.z);
                //WorldToViewNormal
                normalMap = mul((float3x3)UNITY_MATRIX_V, normalMap);

                normal.xy = lerp(normal.xy , normalMap,_StrengthOfNormalMap);
                float2 uv = normal.xy * 0.5 + 0.5;

                float4 col = float4(0,0,0,0);
                // col = lerp(tex2D(_MatCap0, i.uv) , tex2D(_MatCap1, i.uv)
                //         , (length(_TargetVertexColor0 - i.vcol) < 0.001 )
                //         );
                float2 OneZero = float2(1.,0.);
                OneZero = float2(1.,1.);
                col = lerp(tex2D(_MatCap0, uv)  * OneZero.xyxx, tex2D(_MatCap1, uv) * OneZero.yxyx
                , (i.vcol.r > 0.5 )
                );
                // カメラから見た法線のxyをそのままUVとして使う
                return col;
            }

            ENDCG
        }
    }
}