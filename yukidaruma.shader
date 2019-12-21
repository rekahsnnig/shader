//http://tips.hecomi.com/entry/2016/09/26/014539
//参考にさせてもらいました
Shader "raymarching/obj_Yukidaruma"
{
	Properties
	{
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
			#define M(x,y) (x - y * floor(x/y)) - y/2.
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screen : TEXCOORD0;
				float4 vertexW : TEXCOORD1;
				float3 normal : NORMAL;
			};

			float2x2 rot(float a)
			{
				float s = sin(a), c = cos(a);
				return float2x2(c,s,-s,c);
			}
            
			float eq(float a,float b)
			{
				return 1 - abs(sign( a - b ));
			}

			//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.html
			float sdEllipsoid( float3 p, float3 r )
			{
				float k0 = length(p/r);
				float k1 = length(p/(r*r));
				return k0*(k0-1.0)/k1;
			}

			float sdSphere(float3 p,float s)
			{
				return length(p) - s;
			}

			float sdCappedCylinder( float3 p, float h, float r )
			{
				float2 d = abs(float2(length(p.xz),p.y)) - float2(h,r);
				return min(max(d.x,d.y),0.0) + length(max(d,0.0));
			}

			float sdTorus( float3 p, float2 t )
			{
				float2 q = float2(length(p.xz)-t.x,p.y);
				return length(q)-t.y;
			}

			float sdCone( float3 p, float2 c )
			{
				// c is the sin/cos of the angle
				float q = length(p.xy);
				return dot(c,float2(q,p.z));
			}

			float sdCappedCone( float3 p, float h, float r1, float r2 )
			{
				float2 q = float2( length(p.xz), p.y );
				float2 k1 = float2(r2,h);
				float2 k2 = float2(r2-r1,2.0*h);
				float2 ca = float2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
				float2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot(k2,k2), 0.0, 1.0 );
				float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
				return s*sqrt( min(dot(ca,ca),dot(cb,cb)) );
			}

			float2 Head(float3 p)
			{
				float3 headp = p;
				float3 eyesp = p;
				float3 nosep = p;
				float3 bkp = p;

				//head
				headp.y -= 0.2;
				float3 headsize = float3(0.1,0.09,0.1);

				//eye
				float3 ep = float3(0.2,-0.096,0.039);
				eyesp.xy = mul(rot(UNITY_PI/2.),eyesp.xy);
				// eyesp.yz = mul(rot(sign(-eyesp.z)*0.2),eyesp.yz);
				eyesp.z = abs(eyesp.z);

				//nose
				nosep.xy = mul(rot(-UNITY_PI/2.),nosep.xy);
				nosep.y -= 0.1;
				nosep.x += 0.17;

				
				//bucket
				bkp.y -= 0.3;
				bkp.xz += float2(-.01,.01) * sin(bkp.y*120. + _Time.y);

				float hs = sdEllipsoid(headp,headsize);
				float es = sdTorus(eyesp - ep,float2(0.006,0.007));
				float ns = sdCappedCone(nosep,0.07,0.02,0.001);
				float bs = sdCappedCone(bkp,0.07,0.11,0.075) - 0.01;

				float mm = min(min(min(hs,es),ns),bs);
				float id = eq(mm,hs) * 0. +
					   eq(mm,es) * 1. +
					   eq(mm,ns) * 2. +
					   eq(mm,bs) * 3. ;
				return float2( mm , id);
			}

			float2 Body(float3 p)
			{
				float3 bodyp = p;
				float3 btp = p;

				float3 bodysize = float3(0.15,0.13,0.15);
				btp.x -= 0.145;

				float bs = sdEllipsoid(bodyp,bodysize);
				float bts = sdSphere(btp,0.02);
				bts = min(bts ,sdSphere(btp- float3(-0.01,0.049,0),0.02));

				float id = 0.;
				id = (bs > bts)?1.:0.;
				return float2( min(bs,bts),id);
			}

			float2 Arm(float3 p)
			{
				float3 ap = p;

				float angle = 0.5;

				float3 app = float3(0.,-0.21,-.03);
				ap.yz = mul(rot(sign(ap.z)*(UNITY_PI/2.-angle) ),ap.yz);
				ap.y = abs(ap.y);
				float as = sdCappedCone(ap + app,0.08,0.011,0.01);
				return float2(as,0);
			}

			//モデリング部
			float2 dist(float3 p)
			{
				p.y += 0.27;
				p /= 2.;
				float2 head = Head(p) + float2(0.,0.);
						float2 body = Body(p) + float2(0.,4.);
				float2 arm = Arm(p) + float2(0.,6.);

				float mm = min(min(body.x,head.x),arm.x);
				float id = eq(mm,head.x) * head.y +
					   eq(mm,body.x) * body.y +
					   eq(mm,arm.x)  * arm.y;
				return float2(mm,id);
			}

			float3 toLocal(float3 p)
			{
				return mul(unity_WorldToObject, float4(p, 1.)).xyz;
			}

			float2 objDist(float3 p)
			{
				return dist(toLocal(p));
			}

			//http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
			float3 OgetNormal( float3 p ) // for function f(p)
			{
				const float h = 0.0001; // or some other value
				const float2 k = float2(1,-1);
				return normalize(   k.xyy*objDist( p + k.xyy*h ).x + 
						    k.yyx*objDist( p + k.yyx*h ).x + 
						    k.yxy*objDist( p + k.yxy*h ).x + 
						    k.xxx*objDist( p + k.xxx*h ).x );
			}


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screen = o.vertex;
				o.vertexW = mul(unity_ObjectToWorld,v.vertex);
				o.normal = v.normal;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//UNITY_UV_STARTS_AT_TOP,_ScreemParamsは
				//https://qiita.com/edo_m18/items/591925d7fc960d843afa
					#if UNITY_UV_STARTS_AT_TOP
								i.screen.y *= -1.0;
					#endif
					i.screen.x *= _ScreenParams.x / _ScreenParams.y;
					float2 p = i.screen.xy / i.screen.w;
					float3 cp = i.vertexW;
					float3 cd = -UNITY_MATRIX_V[2].xyz;
					float3 cu = UNITY_MATRIX_V[1].xyz;
					float3 cs = UNITY_MATRIX_V[0].xyz;

					//カメラ方向と法線の内積の正負によってレイの開始位置を変えられます
					//外から見るだけならここは不要
					float sep = dot(i.normal, cd);
					cp = step(0, sep) * _WorldSpaceCameraPos
						+ step(sep, 0) * i.vertexW;
					//ここまで

					float target = abs(UNITY_MATRIX_P[1][1]);

					float3 rd = normalize(float3(p.x * cs + p.y * cu + target * cd));

					float depth = 0.;
					float3 normal = 0;
					float3 color = 0;
                    			float id = -1.;
					for (int i = 0; i < 99; i++)
					{
						float3 rp = cp + rd * depth;
						float2 d = objDist(rp);
						if (d.x < DELTA)
						{
							normal = OgetNormal(rp);
							color = normal;
                            				id = d.y;
							break;
						}
                        			if(depth > 20.){discard;}
						depth += d.x;
					}
					float3 light = _WorldSpaceLightPos0.xyz;
					//head 0
					//eye  1
					//nose 2
					//bktt 3 
					//body 4
					//butt 5
					//arm  6
					color = eq(id,0.) * float3(1.,1.,1.)+
					    eq(id,1.) * float3(0.,0.,0.)+
					    eq(id,2.) * float3(1.,0.5,0.)+
					    eq(id,3.) * float3(1.,0.,0.)+
					    eq(id,4.) * float3(1.,1.,1.)+
					    eq(id,5.) * float3(0.18,0.18,0.2)+
					    eq(id,6.) * float3(0.5,0.3,0.1);

					float diff = saturate(dot(light,normal));
					float bou =  0.5 + 0.5 * saturate(dot(normal , float3(0.,-1.,0.)));
					float sky =  0.5 + 0.5 * saturate(dot(normal , float3(0.,1.,0.)));
					color = color * diff;
					color += color * bou;
					color += color * sky;

					color = pow(color,0.4545);
					return float4(color,1);
				}
			ENDCG
		}
	}
}
