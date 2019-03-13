Shader "tonoShader/CloneShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Times("Times",Range(1,24))=1
        _offsetX("Offset X",float)=0.000
        _offsetY("Offset Y",float)=0.000
        _offsetZ("Offset Z",float)=0.000
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
            #pragma geometry geom 
            
            #pragma target 4.0
            
            #include "UnityLightingCommon.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                 float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

           sampler2D _MainTex;
            float4 _MainTex_ST;
            int _Times;
            float _offsetX;
            float _offsetY;
            float _offsetZ;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            [maxvertexcount(84)]
            void geom(triangle v2f input[3],inout TriangleStream <v2f> OutputStream)
            {
                v2f o = (v2f)0;
                float4x4 offset;
                for(int j = 0; j < _Times; j++)
                {
                    [unroll]
                    for(int i = 0; i < 3; i++)
                    {
                        o.normal = input[i].normal;
                        o.vertex = UnityObjectToClipPos(float3( (input[i].vertex.x + _offsetX * j),(input[i].vertex.y + _offsetY * j),(input[i].vertex.z + _offsetZ * j)));
                        OutputStream.Append(o);
                    }
                    OutputStream.RestartStrip();
                }
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
 
                float3 lightDir = float3(1, 1, 0);
                float ndotl = dot(i.normal, normalize(lightDir));
 
                return col * ndotl;
            }
            ENDCG
        }
    }
}
