Shader "Unlit/Geom_confuse01"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
		Tags { "RenderType"="Opaque" }
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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
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
				float Xspeed = (_Speed * count/_Coef * _Xspeed * _Time.y)%360;
				float Yspeed = (_Speed * count/_Coef * _Yspeed * _Time.y)%360;
				float Zspeed = (_Speed * count/_Coef * _Zspeed * _Time.y)%360;
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
					rotate = (_Z>0)?mul(rotate,Zmat):rotate;
				float4x4 Ymat = {
								   float4(cos(Yspeed),0,sin(Yspeed),0),
								   float4(0,1,0,_yRange * count),
								   float4(-sin(Yspeed),0,cos(Yspeed),0),
								   float4(0,0,0,1)
								   };
					rotate = (_Y>0)?mul(rotate,Ymat):rotate;
				float4x4 Xmat = {
								   float4(1,0,0,_xRange * count),
								   float4(0,cos(Xspeed),-sin(Xspeed),0),
								   float4(0,sin(Xspeed),cos(Xspeed),0),
								   float4(0,0,0,1)
								   };
					rotate = (_X>0)?mul(rotate,Xmat):rotate;
				
				
				//return mul(rotate,float4(INmatrix,1));
				return rotate;
			}
			
			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = v.normal;
				return o;
			}

			[maxvertexcount(90) ]
			 void geom(triangle v2g input[3], inout TriangleStream<g2f> OutputStream)
			{

				g2f v = (g2f)0;

				for(int i = 1;i < _Count+1 ;i++)
				{
					[unroll]
					for(int j = 0;j < 3;j++){
					//	v.vertex = UnityObjectToClipPos(float4(mul(v.vertex,MovePos(i)).xyz,1.0));
					//	v.vertex = UnityObjectToClipPos(float3(mul(Move(i),input[j].vertex.xyz) + i * float3(_Range,_Range,_Range)).xyz));
						v.vertex = UnityObjectToClipPos(input[j].vertex);
						v.vertex = UnityObjectToClipPos(float4(mul( Move(i),input[j].vertex ).xyz,1.0));
						v.uv = input[j].uv;
						v.normal = input[j].normal;
						OutputStream.Append(v);
					}
					OutputStream.RestartStrip();
				}
		    }
			
			fixed4 frag (g2f infrag) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, infrag.uv);
				return col;
			}
			ENDCG
		}
		
	}
}
