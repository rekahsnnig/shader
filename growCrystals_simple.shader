Shader "geometry/growCrystals_simple"
{
	Properties
	{
		_CrystalLength("Crystal Length",float) = 0.1
		_CrystalSize1("CrystalSize1",float) = 0.05
		_CrystalSize2("CrystalSize2",float) = 0.05
		_Sharpness("Sharpness",float) = 0.8
		[HDR]_Color("Color",Color) = (1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent"}
		LOD 100
		Cull off
		Blend SrcAlpha OneMinusSrcAlpha
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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _MaskTex;

			float _CrystalLength;
			float _CrystalSize1;
			float _CrystalSize2;
			float _Sharpness;

			float3 _Color;

			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.uv = v.uv;
				return o;
			}

			float3 getNormal(float3 A,float3 B,float3 C)
			{
				float3 C2A = A-C;
				float3 C2B = B-C;
				return normalize(cross(C2A,C2B));
			}

			[maxvertexcount(56) ]
			 void geom(triangle v2g ip[3], inout TriangleStream<g2f> OutputStream)
			{
				g2f v = (g2f)0;

				[unroll]
				for(int j = 0;j < 3;j++){
					v.vertex = UnityObjectToClipPos(ip[j].vertex);
					v.uv = ip[j].uv;
					v.normal = ip[j].normal;
					OutputStream.Append(v);
				}
				OutputStream.RestartStrip();

				g2f o = (g2f)0;

				float3 p0 = ip[0].vertex.xyz;
				float3 p1 = ip[1].vertex.xyz;
				float3 p2 = ip[2].vertex.xyz;

				//六角柱の各頂点の位置を決める係数群
				//まとめた方が分かりやすそうだったのでまとめた
				float3 needle = float3(1./3.,1./3.,1./3.);
				float3 tri =  float3(2./4.,1./4.,1./4.);
				float3 itri = float3(2./5.,2./5.,1./5.);

				
				float3 seed = float3(o.uv,3421.5);

				float3 dir = getNormal(p0,p1,p2);
				
				//
				float3 size1 = _CrystalSize1;
				float3 size2 = _CrystalSize2;
				
				float len =_CrystalLength;


				float3 pp0 = (p0*needle.x  + p1*needle.y + p2*needle.z );
				float3 pp1 = (p0*tri.x   + p1*tri.y  + p2*tri.z);
				float3 pp2 = (p0*itri.x  + p1*itri.y + p2*itri.z );
				float3 pp3 = (p0*tri.y   + p1*tri.x  + p2*tri.z );
				float3 pp4 = (p0*itri.z  + p1*itri.x + p2*itri.y );
				float3 pp5 = (p0*tri.z   + p1*tri.y  + p2*tri.x );
				float3 pp6 = (p0*itri.y  + p1*itri.z + p2*itri.x );

				//中心から頂点へ向かう単位ベクトルを計算
				float3 pv1 = normalize(pp1-pp0);
				float3 pv2 = normalize(pp2-pp0);
				float3 pv3 = normalize(pp3-pp0);
				float3 pv4 = normalize(pp4-pp0);
				float3 pv5 = normalize(pp5-pp0);
				float3 pv6 = normalize(pp6-pp0);

				//中心から見て頂点方向に伸ばす
				pp1 += pv1 * size1;
				pp2 += pv2 * size1;
				pp3 += pv3 * size1;
				pp4 += pv4 * size2;
				pp5 += pv5 * size2;
				pp6 += pv6 * size2;

				
				float3 pp0d = pp0 + dir * _Sharpness;
				//法線の方向にlenの長さ分伸ばす
				float3 pp1d = pp1 + dir * len;
				float3 pp2d = pp2 + dir * len;
				float3 pp3d = pp3 + dir * len;
				float3 pp4d = pp4 + dir * len;
				float3 pp5d = pp5 + dir * len;
				float3 pp6d = pp6 + dir * len;
				
				//g2fのvertexはfloat4で宣言してあるのでfloat3のpp~をfloat4にして一時的にいれるところ
				//わかりやすくするためなのでどっちでもいい
				float4 v4o = float4(0,0,0,0);
				//v4oと同じ
				float4 normal = float4(0,0,0,1);


				//1
				normal = float4(getNormal(pp1,pp2,pp1d),1);
				v4o = float4(pp1,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp2,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp1d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				normal = float4(getNormal(pp1d,pp2,pp2d),1);
				v4o = float4(pp2,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp1d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp2d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				//2
				normal = float4(getNormal(pp2,pp3,pp2d),1);
				v4o = float4(pp2,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp3,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp2d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				normal = float4(getNormal(pp2d,pp3,pp3d),1);
				v4o = float4(pp3,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp3d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp2d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				//3
				normal = float4(getNormal(pp3,pp4,pp3d),1);
				v4o = float4(pp3,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp4,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp3d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				normal = float4(getNormal(pp3d,pp4,pp4d),1);
				v4o = float4(pp4,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp4d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp3d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				//4
				normal = float4(getNormal(pp4,pp5,pp4d),1);
				v4o = float4(pp4,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp5,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp4d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				normal = float4(getNormal(pp4d,pp5,pp5d),1);
				v4o = float4(pp5,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp5d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp4d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				//5
				normal = float4(getNormal(pp5,pp6,pp5d),1);
				v4o = float4(pp5,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp6,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp5d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				normal = float4(getNormal(pp5d,pp6,pp6d),1);
				v4o = float4(pp6,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp6d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp5d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				//6
				normal = float4(getNormal(pp6,pp1,pp6d),1);
				v4o = float4(pp6,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp1,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp6d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				normal = float4(getNormal(pp6d,pp1,pp1d),1);
				v4o = float4(pp1,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp1d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp6d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();


				//top1
				normal = float4(getNormal(pp1d,pp2d,pp0d),1);
				v4o = float4(pp1d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp2d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp0d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				//top2
				normal = float4(getNormal(pp2d,pp3d,pp0d),1);
				v4o = float4(pp2d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp3d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp0d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				OutputStream.RestartStrip();

				//top3
				normal = float4(getNormal(pp3d,pp4d,pp0d),1);
				v4o = float4(pp3d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp4d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp0d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				//top4
				normal = float4(getNormal(pp4d,pp5d,pp0d),1);
				v4o = float4(pp4d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp5d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp0d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);

				//top5
				normal = float4(getNormal(pp5d,pp6d,pp0d),1);
				v4o = float4(pp5d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp6d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp0d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				OutputStream.Append(o);

				//top6
				normal = float4(getNormal(pp6d,pp1d,pp0d),1);
				v4o = float4(pp6d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp1d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
				v4o = float4(pp0d,1);
				o.normal = normal;
				o.vertex = UnityObjectToClipPos(v4o);
				
				OutputStream.Append(o);
		    }
			
			fixed4 frag (g2f i) : SV_Target
			{
				float4 col = float4(_Color,1);
				float3 light = _WorldSpaceLightPos0;

				col.rgb = dot(i.normal,light) * col.rgb;
				return col;
			}
			ENDCG
		}
		
	}
}
