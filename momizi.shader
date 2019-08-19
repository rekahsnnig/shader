Shader "Unlit/momizi"
{
	Properties
	{
		[Toggle]_X("UseX for rotation",float) = 0
		_Xspeed("X speed",float) = 0
		[Toggle]_Y("UseY for rotation",float) = 0
		_Ysoeed("Y speed",float) = 0
		[Toggle]_Z("UseZ for rotation",float) = 0
		_Zspeed("Z speed",float) = 0
		_Speed("Speed ",float) = 0
		_Coef(" coefficient",Range(0.001,10)) = 1
		_xRange("X Range ",Range(0,1)) = 0
		_yRange("Y Range ",Range(0,1)) = 0
		_zRange("Z Range ",Range(0,1)) = 0
		_Count("Count ",Range(1,30)) = 1
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
				#pragma geometry geom

				#include "UnityCG.cginc"


				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float4 normal :NORMAL;
				};

				struct v2g
				{
					float4 vertex : SV_POSITION;
					float2 uv : TEXCOORD0;
					float4 normal :NORMAL;
				};

				struct g2f
				{
					float4 vertex : SV_POSITION;
					float2 uv : TEXCOORD0;
					float4 normal :NORMAL;
					float color : COLOR;
				};

				float _Speed;
				float _xRange;
				float _yRange;
				float _zRange;
				float _Count;
				float _Coef;

				float _X;
				float _Y;
				float _Z;
				float _Xspeed;
				float _Yspeed;
				float _Zspeed;

				float4x4 Move(float count)
				{
					float Xspeed = (_Speed * count / _Coef * _Xspeed * _Time.y) % 360;
					float Yspeed = (_Speed * count / _Coef * _Yspeed * _Time.y) % 360;
					float Zspeed = (_Speed * count / _Coef * _Zspeed * _Time.y) % 360;
					float4x4 rotate = {float4(1,0,0,0),
									   float4(0,1,0,0),
									   float4(0,0,1,0),
										float4(0,0,0,1)};



					float4x4 Zmat = {
									   float4(cos(Zspeed),-sin(Zspeed),0,0),
									   float4(sin(Zspeed),cos(Zspeed),0,0),
									   float4(0,0,1,_zRange * count),
									   float4(0,0,0,1)
									   };
						rotate = (_Z > 0) ? mul(rotate,Zmat) : rotate;
					float4x4 Ymat = {
									   float4(cos(Yspeed),0,sin(Yspeed),0),
									   float4(0,1,0,_yRange * count),
									   float4(-sin(Yspeed),0,cos(Yspeed),0),
									   float4(0,0,0,1)
									   };
						rotate = (_Y > 0) ? mul(rotate,Ymat) : rotate;
					float4x4 Xmat = {
									   float4(1,0,0,_xRange * count),
									   float4(0,cos(Xspeed),-sin(Xspeed),0),
									   float4(0,sin(Xspeed),cos(Xspeed),0),
									   float4(0,0,0,1)
									   };
						rotate = (_X > 0) ? mul(rotate,Xmat) : rotate;


						//return mul(rotate,float4(INmatrix,1));
						return rotate;
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
						float rad = atan(uv.y/uv.x);
						float degree = rad * (180 / 3.141592);
						return degree;
					}

					float2 fold(float2 uv)
					{
						uv.x = abs(uv.x);
						float2 v = float2(0,1);

						[unroll]
						for (int i = 0;i<3;i++)
						{
							uv -= 2.0 * min(0.0,dot(uv,v))*v;
							v = normalize(v - float2(1.0,0));
						}
						return uv;
					}

					/*float pmod(float2 uv,float count,float l)
					{
						float tPI = 3.141592 * 2;
						float a = atan(uv.y/uv.x);
						a = min(l * tPI/count,a);
						a = fmod(a, tPI / count) - 5 * tPI / count;
						return length(uv) * float2(sin(a),cos(a));
					}
					*/
					float2 rot(float2 v,float theta)
					{
						float2x2 mat = float2x2(
													float2(cos(theta),-sin(theta)),
													float2(sin(theta),cos(theta))
												);
						return mul(v,mat);
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

						col.r +=col.r + step(length(in_uv), 0.2);
						float red = step(abs(in_uv.y), 0.04) * step(0, in_uv.x) * step(length(shifteduv), 0.79);
									
						col.r = max(col.r,red) ;
						return col;
					}

					v2g vert(appdata v)
					{
						v2g o;
						o.vertex = v.vertex;
						o.uv = v.uv;
						o.normal = v.normal;
						return o;
					}

					[maxvertexcount(90)]
					 void geom(triangle v2g input[3], inout TriangleStream<g2f> OutputStream)
					{

						g2f v = (g2f)0;

						for (int i = 1;i < _Count + 1;i++)
						{
							[unroll]
							for (int j = 0;j < 3;j++) {
									v.vertex = UnityObjectToClipPos(input[j].vertex);
									v.vertex = UnityObjectToClipPos(float4(mul(Move(i),input[j].vertex).xyz,1.0));
									v.uv = input[j].uv;
									v.normal = input[j].normal;
									v.color = random2(float2(i,i));
									OutputStream.Append(v);
								}
								OutputStream.RestartStrip();
							}
						}

						fixed4 frag(g2f infrag) : SV_Target
						{
							float2 uv = (infrag.uv - float2(0.5,0.5) ) * 2;
							
							fixed4 col = momizi(uv);

							if (col.r < 1) { discard; }
							col.g = infrag.color;
							col.r = 1.5;
							float noise = 1 - (fBm(uv*300,5));
							return col * noise + 0.1;
						}
						ENDCG
					}

		}
}
