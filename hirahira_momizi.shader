Shader "Unlit/hirahira_momizi"
{
	Properties
	{

		_Speeds("speed",vector) = (1,1,1,0)
		_Axioses("axioses",vector) = (1,1,1,0)
		_Size("Size",float) = 0.9
		_Hight("Hight",float) = 1
		_Range("Range",float) = 10
		_Shake("Shake",float) = 1
		_ShakeFrequency("ShakeFrequency",float) = 100
		_RateOfFallingApart("Rate of falling apart",float) = 100
		_Offset("Offset",float) = 0
		_TessFactor("Tess Factor",Vector) = (2,2,2,2)
		_FallenSpeed("FallenSpeed",float) = 1
		[Toggle]_Inverse("Inverse", float) = 0
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
		CULL OFF
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma hull HS
			#pragma domain DS
			#pragma geometry geom

			#pragma target 5.0

			

			#define INPUT_PATCH_SIZE 3
			#define OUTPUT_PATCH_SIZE 3

			#include "UnityCG.cginc"

			uniform vector _TessFactor;
			float _FallenSpeed;


			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2h
			{
				float4 vertex : POSITION;
			};

			struct h2d_main {
				float3 vertex : POITION;
			};

			struct h2d_const {
				float tess_factor[3] : SV_TessFactor;
				float InsideTessFactor : SV_InsideTessFactor;
			};

			struct d2g {
				float4 vertex:SV_Position;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 normal :NORMAL;
				float color : COLOR;
			};


			float4 _Speeds;
			float4 _Axioses;

			float _Size;
			float _Hight;
			float _Range;
			float _Shake;
			float _ShakeFrequency;
			float _RateOfFallingApart;
			float _Offset;
			float _Inverse;

				float4x4 Move(float3 speed)
				{
					float Xspeed = (speed.x * _Time.y);
					float Yspeed = (speed.y * _Time.y);
					float Zspeed = (speed.z * _Time.y);
					float4x4 rotate = {float4(1,0,0,0),
									   float4(0,1,0,0),
									   float4(0,0,1,0),
										float4(0,0,0,1)};



					float4x4 Zmat = float4x4(
									   float4(cos(Zspeed),-sin(Zspeed),0,0),
									   float4(sin(Zspeed),cos(Zspeed),0,0),
									   float4(0,0,1,0),
									   float4(0,0,0,1)
									   );
						rotate = mul(rotate,Zmat);
					float4x4 Ymat = float4x4(
									   float4(cos(Yspeed),0,sin(Yspeed),0),
									   float4(0,1,0,0),
									   float4(-sin(Yspeed),0,cos(Yspeed),0),
									   float4(0,0,0,1)
									  );
						rotate = mul(rotate,Ymat);
					float4x4 Xmat = float4x4(
									   float4(1,0,0,0),
									   float4(0,cos(Xspeed),-sin(Xspeed),0),
									   float4(0,sin(Xspeed),cos(Xspeed),0),
									   float4(0,0,0,1)
									 );
						rotate = mul(rotate,Xmat);

						return rotate;
				 }

				fixed2 random2(fixed2 st) {
					st = fixed2(dot(st, fixed2(127.1, 311.7)),
						dot(st, fixed2(269.5, 183.3)));
					return -1.0 + 2.0*frac(sin(st)*438.5453123);
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

				float fBm(fixed2 st, float octaves)
				{
					float f = 0;
					fixed2 q = st;
					[unroll]
					for (int i = 1;i < octaves;i++) {
						f += perlinNoise(q) / pow(2, i);
						q = q * (2.00 + i / 100);
					}

					return f;
				}

				float equal(float a, float b)
				{
					return abs(sign(a - b));
				}


				float Angle(float2 uv)
				{
					uv = float2(uv.x,abs(uv.y));
					float rad = atan(uv.y / uv.x);
					float degree = rad * (180 / 3.141592);
					return degree;
				}

				float2 fold(float2 uv)
				{
					uv.x = abs(uv.x);
					float2 v = float2(0,1);

					[unroll]
					for (int i = 0;i < 3;i++)
					{
						uv -= 2.0 * min(0.0,dot(uv,v))*v;
						v = normalize(v - float2(1.0,0));
					}
					return uv;
				}
				float2 rot(float2 v,float theta)
				{
					float2x2 mat = float2x2(
												float2(cos(theta),-sin(theta)),
												float2(sin(theta),cos(theta))
											);
					return mul(v,mat);
				}

				float2x2 rot(float theta)
				{
					float2x2 mat = float2x2(
												float2(cos(theta),-sin(theta)),
												float2(sin(theta),cos(theta))
											);
					return mat;
				}

				float2 logarithmic_Spiral(float a,float b,float theta)
				{
					float r = a * exp(b * theta);
					float2 result = float2(r * cos(theta),r * sin(theta));
					return result;
				}

				float2 circle(float2 pos,float range)
				{
					return float2(1,1);
				}

				float4 momizi(float2 in_uv)
				{
					float2 uv = rot(in_uv, 75);
					uv = fold(uv);
					float4 col = float4(uv,uv);
					float2 shiftuv = float2(0.78,0.1);
					float2 shifteduv = float2(shiftuv - uv);
					col.r = step(length(shifteduv), 0.79);// *step(length(uv - float2(0.01, 0)), 0.1);
					col.g = 0;
					col.b = 0;
					col.r = col.r - (step(0,Angle(in_uv))* step(Angle(in_uv),24));

					col.r += col.r + step(length(in_uv), 0.2);
					float red = step(abs(in_uv.y), 0.04) * step(0, in_uv.x) * step(length(shifteduv), 0.79);

					col.r = max(col.r,red);
					return col;
				}

				float3 getNormal(float4 one,float4 two ,float4 three)
				{
					float4 edge1 = one - two;
					float4 edge2 = three - two;
					return normalize(cross(edge1,edge2));
				}

				float mod(float x, float y)
				{
					return x - y * floor(x / y);
				}

				float mod(float2 xy, float y)
				{
					return xy - y * floor(xy / y);
				}



				v2h vert(appdata v)
				{
					v2h o;
					o.vertex = v.vertex;
					return o;
				}

				h2d_const HSConst(InputPatch<v2h, INPUT_PATCH_SIZE> i) {
					h2d_const o = (h2d_const)0;
					o.tess_factor[0] = _TessFactor.x;
					o.tess_factor[1] = _TessFactor.y;
					o.tess_factor[2] = _TessFactor.z;
					o.InsideTessFactor = _TessFactor.w;
					return o;
				}

				[domain("tri")]
				[partitioning("integer")]
				[outputtopology("triangle_cw")]
				[outputcontrolpoints(OUTPUT_PATCH_SIZE)]
				[patchconstantfunc("HSConst")]
				h2d_main HS(InputPatch<v2h, INPUT_PATCH_SIZE> i, uint id:SV_OutputControlPointID) {
					h2d_main o = (h2d_main)0;
					o.vertex = i[id].vertex;
					return o;
				}

				[domain("tri")]
				d2g DS(h2d_const hs_const_data, const OutputPatch<h2d_main, OUTPUT_PATCH_SIZE> i, float3 bary:SV_DomainLocation) {
					d2g o = (d2g)0;
					float3 vertex = i[0].vertex * bary.x + i[1].vertex * bary.y + i[2].vertex * bary.z;
					o.vertex = float4(vertex, 1);
					return o;
				}


				[maxvertexcount(30)]
				 void geom(triangle d2g inp[3], inout TriangleStream<g2f> OutputStream)
				{
					float size  = _Size;
					float hight = _Hight;
					float range = _Range;
					float shake = _Shake;
					float offset = _Offset;
					float fallen = _FallenSpeed;
					g2f v = (g2f)0;
					g2f w = (g2f)0;
					g2f x = (g2f)0;

					float3 Max_speeds = _Speeds.xyz;
					float3 axioses = _Axioses.xyz;
					
					float4 normal = float4(1,1,1,1);
						[unroll]
						 for (int j = 0;j < 3;j++)
						 {
							float3 origin = float3(random2((inp[j].vertex.xy + inp[j].vertex.yz + inp[j].vertex.xz + inp[j].vertex.yx + inp[j].vertex.zy + inp[j].vertex.zx)).x,
													random2((inp[j].vertex.xy - inp[j].vertex.yz - inp[j].vertex.xz - inp[j].vertex.yx - inp[j].vertex.zy - inp[j].vertex.zx)).x,
													random2(float2(inp[j].vertex.xy + inp[j].vertex.yz + inp[j].vertex.xz  )).y  );
							float i = 6.6338284 * length(origin);
							origin = origin.xzy;
							origin.xz = (origin.xz) * 2 * range;
							origin.y = (origin.y - 0.5) *2 +hight ;
							float4 position = float4(0,0,0,0);
							float3 add = float3(0,0,0);
							float Oseed = origin.x + origin.z;
							float2 randSeed = random2(origin.xy + origin.yz + origin.zx);
							float origCoef = fBm(randSeed * exp(2.197141), 1) + 0.5;
							float2 seed2 = origin.xz + origin.yz + origin.yx + i +j;
							float seed = length(origin) * (i + j);
							float fallenSpeed = (_Time.y*fallen) + fBm(float2(seed,seed2.y),4)* 5;

							if (_Inverse > 0) {
								add.y = (mod((fallenSpeed - offset), hight));
							}
							else {
								add.y = (hight - mod((fallenSpeed - offset), hight));
							}

							add.xz += float2(sin(_Time.y/ _ShakeFrequency + _RateOfFallingApart * random2(seed2).x) * shake
								           , sin(_Time.y/ _ShakeFrequency + _RateOfFallingApart * random2(seed2).y) * shake);
							//add.xz = rot(add.xz,_Time.x);

							//float coef = sign(step(normalize(length(origin)),0.5)-0.5);
							// coef = -1;
							
							// origin.xz = rot(origin.xz,_Time.z);
						   //float a = 100 * normalize(length(origin));
						   //a = pow(fBm(origin.xz,4),2) * 7;
						   //float b = 0.1 * pow(fBm(origin.xz,4),0) * coef;
						   //float rotate_speed = add.y;
							//origin.xz = logarithmic_Spiral(a,b,rotate_speed);
							
							float3 speedCoef = float3(1,1,1);
							//speedCoef = add.y - origCoef + 2.197652181;
							speedCoef = float3(length(random2(float2(i + j,length(origin.xz))) * add.y )
												, length(random2(float2(i - j, length(origin.yz))) * add.y)
													,length(random2(float2(i * j, length(origin.xy))) * add.y));
							speedCoef = normalize(speedCoef*_Time.y);

							float3 speed = float3(0,0,0);
							speed.x = speedCoef.x * Max_speeds.x;
							speed.y = speedCoef.y * Max_speeds.y;
							speed.z = speedCoef.z * Max_speeds.z;

							float axiosCoef = normalize((origin.x + origin.y + origin.y) /(0.001+origin.x-origin.y-origin.z) - cos(_Time.y * speedCoef));
							float3 axios = float3(0,0,0);
							axios.x = axiosCoef * axioses.x;
							axios.y = axiosCoef * axioses.y;
							axios.z = axiosCoef * axioses.z;
							float4x4 mat = Move(speed);

							//origin.xz = rot((origin.xz + origin.yy)/speedCoef+axiosCoef, add.y * fBm(origin.yz + origin.xy, 4));
							origin += add;

							origin -= axios;

							v.color = random2(float2(seed,i));
							w.color = v.color;
							x.color = v.color;

							v.vertex.xyz = float3(size / 2,size / 2,0) + axios;
							v.vertex.xyz = mul(v.vertex,mat).xyz + origin;
							v.uv = float2(0,0);

							w.vertex.xyz = float3(size / 2,-size / 2,0) + axios;
							w.normal = float4(1, 1, 1, 1);
							w.vertex.xyz = mul(w.vertex,mat).xyz + origin;
							w.uv = float2(1,0);

							x.vertex.xyz = float3(-size / 2,size / 2,0) + axios;
							x.normal = float4(1, 1, 1, 1);
							x.vertex.xyz = mul(x.vertex,mat).xyz + origin;
							x.uv = float2(0,1);


							normal.xyz = getNormal(v.vertex,w.vertex,x.vertex);
							v.normal = normal;
							w.normal = normal;
							x.normal = normal;

							v.vertex = UnityObjectToClipPos(v.vertex);
							w.vertex = UnityObjectToClipPos(w.vertex);
							x.vertex = UnityObjectToClipPos(x.vertex);

							OutputStream.Append(v);
							OutputStream.Append(w);
							OutputStream.Append(x);
							OutputStream.RestartStrip();


							v.vertex.xyz = float3(size / 2,-size / 2,0) + axios;
							v.vertex.xyz = mul(v.vertex,mat).xyz + origin;
							v.uv = float2(1,0);

							w.vertex.xyz = float3(-size / 2,-size / 2,0) + axios;
							w.vertex.xyz = mul(w.vertex,mat).xyz + origin;
							w.uv = float2(1,1);

							x.vertex.xyz = float3(-size / 2,size / 2,0) + axios;
							x.vertex.xyz = mul(x.vertex,mat).xyz + origin;
							x.uv = float2(0,1);

							normal.xyz = getNormal(v.vertex, w.vertex, x.vertex);
							v.normal = normal;
							w.normal = normal;
							x.normal = normal;

							v.vertex = UnityObjectToClipPos(v.vertex);
							w.vertex = UnityObjectToClipPos(w.vertex);
							x.vertex = UnityObjectToClipPos(x.vertex);

							OutputStream.Append(v);
							OutputStream.Append(w);
							OutputStream.Append(x);
							OutputStream.RestartStrip();
						 }
				 }

				 fixed4 frag(g2f infrag) : SV_Target
				 {
					 float2 uv = (infrag.uv - float2(0.5,0.5)) * 2;

					 fixed4 col = momizi(uv);

					 if (col.r < 1) { discard; }
					 col.g = infrag.color;
					 col.r = 1.5;
					 float noise = 1 - (fBm(uv * 300,5));
					 return col * noise + 0.1;
				 }
					 ENDCG
			 }

	}
}
