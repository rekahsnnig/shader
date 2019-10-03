Shader "Unlit/icebreak"
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			#define M(x,y) (x - y * floor(x/y)) - y/2.
			#define eq(x,y) (1.-sign(abs(x - y))-0.5)*2.
			#define fsin(x) fract(sin(x))
			#define S(a) clamp(a,1.,0.)
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertexW : TEXCOORD0;
				float3 normal:NORMAL;
				float4 vertex : SV_POSITION;
			};

			float pi = acos(-1.0);
			float pi2 = UNITY_PI * 2;

			float dsphere(float3 p, float s)
			{
				return length(p) - s;
			}

			float dbox(float3 p, float3 s)
			{
				p = abs(p) - s;
				return max(p.x, max(p.y, p.z));
			}

			float2x2 rot(float a)
			{
				float s = sin(a), c = cos(a);
				return float2x2(s, c, -c, s);
			}

			float2 pmod(float2 p, float r)
			{
				float a = UNITY_PI/r - atan2(p.x, p.y) ;
				float n = UNITY_TWO_PI / r;
				a = floor(a / n) * n;
				return mul(rot(a) , p);
			}

			float3 IFS(float3 p)
			{
				for (int i = 0; i < 5; i++)
				{
					p = abs(p) - 1.5;
					p.xz = mul(rot(1.) , p.xz);
					p.xy = mul(rot(1.) , p.xy);
				}
				return p;
			}

			float dist(float3 p)
			{
				p = IFS(p);

				float3 s = float3(0.55, 0.55, 0.55);
			//	float bo = dbox(p, s);

				p = fmod(p, 7.);
				for (int i = 0; i < 4; i++)
				{
					p = abs(p) - 1.11;
					p.xz = mul(rot(1.),p.xz);
					p.xy = mul(rot(1.),p.xy);
				}


				p.yz = pmod(p.yz, 4.);
				p.xy = pmod(p.xy, 4.);

				return (dbox(p, s));
			}

			float3 getNormal(float3 p)
			{
				float3 d = float3(0.001, 0., 0.);

				return normalize(float3(
					dist(p.x + d) - dist(p.x - d),
					dist(p.y + d.yxz) - dist(p.y - d.yxz),
					dist(p.z + d.zyx) - dist(p.z - d.zyx)
				));
			}

			float3 hsv(float h, float s, float v)
			{
				return ((clamp(abs(frac(h + float3(0., 2., 1.) / 3.)*6. - 3.) - 1., 0., 1.) - 1.)*s + 1.)*v;
			}


			inline float3 GetCameraPosition() { return _WorldSpaceCameraPos; }
			inline float3 GetCameraForward() { return -UNITY_MATRIX_V[2].xyz; }
			inline float3 GetCameraUp() { return UNITY_MATRIX_V[1].xyz; }
			inline float3 GetCameraRight() { return UNITY_MATRIX_V[0].xyz; }
			inline float  GetCameraFocalLength() { return abs(UNITY_MATRIX_P[1][1]); }


			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = v.normal;
				o.vertexW = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				 float3 xAxis = GetCameraRight();
				float3 yAxis = GetCameraUp();
				float3 zAxis = GetCameraForward();

				float2 screenPos = 2 * (i.vertex.xy / i.vertex.w - 0.5);
				screenPos.x *= _ScreenParams.x / _ScreenParams.y;

				float2 p = 2 * i.normal.xz -float2(1,1);
				float3 color = float3(0,0,0);
				float windowMax = max(1.,1.);

				float t = _Time.y * 2.;

				//p *= rot(t/20.);

				float3 light = float3(0.,0.,2.);
				float3 cp = i.vertexW;
				float3 cd = float3(0.,0.,1);
				float3 cu = float3(0.,1.,0.);
				float3 cs = normalize(cross(cd , cu));

				float target = 2.5;
				float3 rd = normalize((xAxis * screenPos.x) +
										(yAxis * screenPos.y) +
										(zAxis * GetCameraFocalLength()));

				//	cp += cu * 5.5* clamp(cos(t / 20.),-0.8,0.8);
				//	cp += cs * 5.5 * clamp(sin((t + 5.) / 20.),-0.8,0.8);

				float depth = 0.0;
				float ac = 0.0;
				float3 normal;
				float elect = 0.;
				float3 rp;
				float d = 0.;

				for (int i = 0; i < 99; i++)
				{
					rp = cp + rd * depth;
					rp.xz = mul(rot(1.),rp.xz);
					d = dist(rp);
					d = length(rp) - 0.9;
					if (d < 0.001)
					{
						 normal = getNormal(rp);
						 color = normal;
						 break;
					}
					ac += exp(-d * 3.);
					depth += d;
				 }
				if (d > 0.001) { discard; }
				 return float4(color, 1.);
			}
			ENDCG
		}
	}
}
