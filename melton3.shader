Shader "raymarching/molten_para"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Depth("Texture", 2D) = "white" {}
		_Scale("Scale",vector) = (1,1,1,1)
		_boxPos("box position",vector) = (0,0,0,0)
		_Size("SphereSize",float) = 1
		_walloffset("wall offset",vector) = (0,0,0,0)
	}
		SubShader
		{
			Tags {"RenderType" = "Queque"}
			LOD 100
			Cull off
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				#define DELTA 0.001
				#define MAX3(x,y,z) max(max(x,y),z)
				#define M(x,y) (x - y * floor(x/y)) - y/2.
				#define eq(x,y) (1.-sign(abs(x - y))-0.5)*2.
				#define fsin(x) fract(sin(x))
				#define S(a) clamp(a,1.,0.) 
				#define MAX_WALLDISTANCE 100
				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float2 uv: TEXCOORD0;
				};

				struct v2f
				{
					float4 vertexW : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float4 screen : TEXCOORD1;
					float3 normal : NORMAL;
				};

				struct raymarchingOut {
					float3 color;
					float2 map;
					float3 rd;
					float3 cp;
					float3 cd;
				};

				struct dOut {
					float d;
					float id;
					float distance;
					float3 sCenter;
					float3 bCenter;
				};

				uniform float3 _Scale;
				uniform float3 _boxPos;
				uniform float _Size;
				sampler2D _Depth;
				float4 _Depth_ST;
				uniform float3 _walloffset;


				sampler2D _MainTex;
				float4 _MainTex_ST;



				//https://wgld.org/d/glsl/g016.html
				float smoothMin(float d1, float d2, float k) {
					float h = exp(-k * d1) + exp(-k * d2);
					return -log(h) / k;
				}

				float Dxyplane(float3 p)
				{
					return p.z + 10;
				}
				fixed2 random2(fixed2 st) {
					st = fixed2(dot(st, fixed2(127.1, 311.7)),
						dot(st, fixed2(269.5, 183.3)));
					return -1.0 + 2.0*frac(sin(st)*43758.5453123);
				}

				float perlinNoise(fixed2 st)
				{
					fixed2 p = floor(st);
					fixed2 f = frac(st);
					fixed2 u = f * f*(3.0 - 2.0*f);

					float v00 = random2(p + fixed2(0, 0));
					float v10 = random2(p + fixed2(1, 0));
					float v01 = random2(p + fixed2(0, 1));
					float v11 = random2(p + fixed2(1, 1));

					return lerp(lerp(dot(v00, f - fixed2(0, 0)), dot(v10, f - fixed2(1, 0)), u.x),
						lerp(dot(v01, f - fixed2(0, 1)), dot(v11, f - fixed2(1, 1)), u.x),
						u.y) + 0.5f;
				}
				float sdSphere(float3 p,float size)
				{
					return length(p) - size;
				}

				//http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
				float sdBox(float3 p,float3 b)
				{
					float3 d = abs(p) - b;
					//    d.z = p.z;
						return length(max(d, 0.0))
							+ min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
					}

					float sdBox(float3 p,float3 b,float3 offset)
					{
						float3 d = abs(p) - b;
						d += offset;
						//    d.z = p.z;
							return length(max(d, 0.0))
								+ min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
						}

						float sdPlane(float3 p, float4 n)
						{
							// n must be normalized
							return dot(p, n.xyz) + n.w;
						}

						dOut dist(float3 ip)
						{
							float3 pos1 = ip + _boxPos;
							float3 pos2 = ip + float3(0,0,1)*_Scale;
							float size = _Size;
							float s = sdSphere(pos1,size);
							//s = sdBox(pos1, size, float3(0, 0, 0));
							float bb = sdBox(pos2,float3(1,1,1.1) *abs(_Scale / 2),_walloffset);
							//bb = sdPlane(ip,float4(0,0,-1,1));
							//bb = 100.;
							float coef = (normalize(distance(pos1, pos2)));
							dOut o;
							o.d = smoothMin(s, bb, coef);
							o.id = step(length(s),length(bb));
							o.distance = distance(s,bb);
							o.sCenter = pos1;
							o.bCenter = pos2 + _walloffset;
							return o;
						}

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
							float a = UNITY_PI / r - atan2(p.x, p.y);
							float n = UNITY_TWO_PI / r;
							a = floor(a / n) * n;
							return mul(rot(a), p);
						}

						float3 IFS(float3 p)
						{
							for (int i = 0; i < 5; i++)
							{
								p = abs(p) - 1.5;
								p.xz = mul(rot(1.), p.xz);
								p.xy = mul(rot(1.), p.xy);
							}
							return p;
						}

						float dist2(float3 p,float3 offset)
						{
							p += offset;
							p = IFS(p);

							float3 s = float3(0.55, 0.55, 0.55);
							//  float bo = dbox(p, s);

							p = fmod(p, 7.);
							for (int i = 0; i < 4; i++)
							{
								p = abs(p) - 1.11;
								p.xz = mul(rot(1.), p.xz);
								p.xy = mul(rot(1.), p.xy);
							}


							p.yz = pmod(p.yz, 4.);
							p.xy = pmod(p.xy, 4.);

							return (dbox(p, s));
						}

						float3 hsv(float h, float s, float v)
						{
							return ((clamp(abs(frac(h + float3(0., 2., 1.) / 3.)*6. - 3.) - 1., 0., 1.) - 1.)*s + 1.)*v;
						}

						float3 toLocal(float3 p)
						{
							return mul(unity_WorldToObject, float4(p, 1.)).xyz * abs(_Scale);
						}

						dOut objDist(float3 p)
						{
							return dist(toLocal(p));
						}

						float3 OgetNormal(float3 p)
						{
							float3 d = float3(DELTA,0,0);
							return normalize(float3(
								objDist(p + d).d - objDist(p - d).d,
								objDist(p + d.yxz).d - objDist(p - d.yxz).d,
								objDist(p + d.zyx).d - objDist(p - d.zyx).d
								));
						}

						float3 getNormal(float3 p,float3 o)
						{
							float3 d = float3(DELTA, 0, 0);
							//p += o;
							return normalize(float3(
								dist2(p + d ,o) - dist2(p - d, o),
								dist2(p + d.yxz, o) - dist2(p - d.yxz, o),
								dist2(p + d.zyx, o) - dist2(p - d.zyx, o)
								));
						}

						float2 GetScreenPos(float4 screenPos)
						{
							#if UNITY_UV_STARTS_AT_TOP
												screenPos.y *= -1.0;
							#endif
							screenPos.x *= _ScreenParams.x / _ScreenParams.y;
							return screenPos.xy / screenPos.w;
						}

						float dist3(float3 p)
						{
							for (int i = 0; i < 3; i++)
							{
								p.x = abs(p.x) - 1.0;
								p.xz = mul(rot(2.),p.xz);
							}
							p = M(p,4.);
							float s = dbox(p,float3(1,1,1));
							return s;
						}

						v2f vert(appdata v)
						{
							v2f o;
							o.vertex = UnityObjectToClipPos(v.vertex);
							o.vertexW = mul(unity_ObjectToWorld,v.vertex);
							o.screen = o.vertex;
							o.normal = v.normal;
							return o;
						}


						raymarchingOut inraymarching(raymarchingOut ri)
						{
							float t = _Time.y;
							float2 uvmap = -1;
							float3 offset = float3(0,0,-20);
							float depth = 0.;
							float ac = 0.;
							float elect = 0.;
							float3 rp;
							float3 normal;
							float3 light = float3(0, 0, 2);
							ri.cp += ri.cd * t;
							for (int i = 0; i < 90; i++)
							{
								rp = ri.cp + ri.rd * depth;
								//rp.xz = mul(rot(1.), rp.xz);
								float d = dist2(rp,float3(0,0,15)*_Scale);
								if (d < 0.001)
								{
									uvmap = (rp.xy / (_Scale / 2) + 1) / 2;
									normal = getNormal(rp, offset);
									elect = clamp(length(rp.xy - ri.cp.xy * S(sin(t / 1.)*5.)), 0., 10.);
									break;
								}
								ac += exp(-d * 3.);
								depth += d;
							}
							float3 color = 0;
							color.rgb = (ac / 100.);

							float h = frac(sin(ac / 50.));
							float s = 1.;
							float v = 3. / ac;

							color = hsv(h, s, v);

							color.b = elect;
							color = color * pow(dot(normal, light), 2.);
							raymarchingOut ro;
							ro = ri;
							ro.color = color;
							ro.map = uvmap;
							ro.cd = ri.cd;
							return ro;
						}

						raymarchingOut inraymarching2(raymarchingOut ri)
						{
							float t = _Time.y;
							float2 uvmap = -1;
							float3 offset = float3(0, 0, -20);
							float depth = 0.;
							float3 rp;
							float3 normal;
							float3 light = float3(0, 0, 2);

							float3 color = 0;
							//ri.cp += ri.cd * t;

							float ac = 0.;
							for (int i = 0; i < 90; i++)
							{
								rp = ri.cp + ri.rd * depth;
								//rp.xz = mul(rot(1.), rp.xz);
							   // float d = length(fmod(rp,4.)) - 0.9;
								float d = dist3(rp);
								ac += exp(max(abs(d),0.001)*-3.);
								if (d < 0.01)
								{
									uvmap = (rp.xy / (_Scale / 2) + 1) / 2;
									normal = getNormal(rp,float3(0,0,0));
									// color = 1;
									// break;
								 }
								 depth += d;
							 }
							 color = ac / 100.;
							 //color = color * pow(dot(normal, light), 2.);
							 raymarchingOut ro;
							 ro = ri;
							 ro.color = color;
							 ro.map = uvmap;
							 ro.cd = ri.cd;
							 return ro;
						 }

						 raymarchingOut raymarching(float4 screen,float3 worldp,float3 inormal)
						 {
							 float2 p = GetScreenPos(screen);
							 float3 cp = _WorldSpaceCameraPos;
							 float3 cd = -UNITY_MATRIX_V[2].xyz;
							 float3 cu = UNITY_MATRIX_V[1].xyz;
							 float3 cs = UNITY_MATRIX_V[0].xyz;

							 float sep = dot(inormal, cd);
							 cp = step(0, sep) * cp + step(sep, 0) * worldp;
							 float target = abs(UNITY_MATRIX_P[1][1]);

							 float3 rd = normalize(float3(p.x * cs + p.y * cu + target * cd));
							 float3 rp;
							 float2 uvmap = -20;
							 float depth = 0.;
							 float3 normal = 0;
							 float3 color = 0;

							 raymarchingOut ro;
							 dOut d;
							 for (int i = 0; i < 45; i++)
							 {
								 rp = cp + rd * depth;
								 d = objDist(rp);
								 if (d.d < 0.001)
								 {
									 uvmap = normalize((rp.xy / _Scale / 2 + 1) / 2);
									 normal = OgetNormal(rp);
									 color = abs(normal);
									 ro.cp = rp;
									 break;
								 }
								 depth += d.d;
							 }
							 ro.color = color;

							 ro.rd = normalize(float3(uvmap.x * cs + uvmap.y * cu + cd * target));
							 ro.map = uvmap;
							 ro.cd = cd;
							 ro.cp = rp;

							 float left = length(d.sCenter.xy)/2 + perlinNoise(d.sCenter.xy)/2 * length(d.sCenter.xy);
							 float right = sign(d.sCenter.z - d.bCenter.z) * length(d.sCenter.z - d.bCenter.z) + 0.78 * (abs(_Scale.z));
							if (uvmap.x > 0) {
								 ro = inraymarching2(ro);
								 if (d.id > 0)
								 {
									 ro = inraymarching(ro);
									 //ro.color = 1;
								 }
								 if (d.id <1 && left < right )
								 {
									 ro = inraymarching(ro);
								 }
							 }
							 return ro;
						 }


						 //UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture,i.uv))
						 fixed4 frag(v2f i) : SV_Target
						 {
							 raymarchingOut ro = raymarching(i.screen,i.vertexW,i.normal);
							 if (ro.map.x < -10) { discard; }
							 //if(max(max(ro.color.r,ro.color.g),ro.color.b)<0.1){discard;}
							 //float4 color = tex2D(_MainTex,ro.map);
							 float4 color = float4(ro.color,1);
							 return color;
						 }
					 ENDCG
				 }
		}
}
