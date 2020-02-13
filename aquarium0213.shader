Shader "Unlit/fish"
{
    Properties
    {
        _FishScale("Fish Scale",float) = 1.0
        _KelpScale("Kelp Scale",float) = 1.0
        _ShellScale("Shell Scale",float) = 1.0
        _BubbleScale("Bubble Scale",float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        LOD 100
        Cull off
		Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define OBJ true
            #define TOON false

            #define MARCH 200

            #define SAND 0.
            #define FISH 1.
            #define KELP 2.
            #define SHELL 3.
            #define BUBBLE 4.

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 ro :TEXCOORD0;
                float3 surf :TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _FishScale;
            float _KelpScale;
            float _ShellScale;
            float _BubbleScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                if(OBJ){
                    o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                    o.surf = v.vertex;
                }else{
                    o.ro = _WorldSpaceCameraPos;
                    o.surf = mul(unity_ObjectToWorld,float4(v.vertex.xyz,1));
                }
                
                return o;
            }

            #define S(a) (sin(a) +1.)/2.
            #define DELTA 0.0001

            float3x3 RotMat(float3 axis, float angle)
            {
                // http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
                axis = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float oc = 1.0 - c;
                
                return float3x3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
                                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
                                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
            }

            float smin( float a, float b, float k )
            {
                float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
                return lerp( b, a, h ) - k*h*(1.0-h);
            }

            float mod(float x , float y)
            {
                return x - y * floor(x / y);
            }

            float2 mod(float2 x , float2 y)
            {
                return x - y * floor(x / y);
            }

            float2 RepLim( float2 p, float s, float2 l )
            {
                return p-s*clamp(round(p/s),-l,l);
            }

            float RepLim( float p, float s, float l )
            {
                return p-s*clamp(round(p/s),-l,l);
            }

            float ssphere(float3 p,float3 scale,float s)
            {
                return (length(p/scale)-s)*min(scale.x,min(scale.y,scale.z));
            }

            float sscube(float3 p,float3 s)
            {
                p = abs(p) - s;
                return max(max(p.z,p.y),p.x);
            }

            float dispacement(float3 p)
            {
                return sin(p.x*20.)*sin(p.y*20.)*sin(p.z*20.);
            }

            float c(float x, float f)
            {
                return x - (x - x * x) * -f;
            }

            float rand(float2 co){
                return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
            }

            float2 random2(float2 c) {
                float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
                float2 r;
                r.x = frac(512.0*j);
                j *= .125;
                r.y = frac(512.0*j);
                return r-0.5;
            }

            float3 random3(float3 c) {
                float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
                float3 r;
                r.z = frac(512.0*j);
                j *= .125;
                r.x = frac(512.0*j);
                j *= .125;
                r.y = frac(512.0*j);
                return r-0.5;
            }
            
            float3 random33(float3 st)
            {
                st = float3(dot(st, float3(127.1, 311.7,811.5)),
                            dot(st, float3(269.5, 183.3,211.91)),
                            dot(st, float3(511.3, 631.19,431.81))
                            );
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float perlinNoise(float2 st) 
            {
                float2 p = floor(st);
                float2 f = frac(st);
                float2 u = f*f*(3.0-2.0*f);

                float v00 = rand(p+float2(0,0));
                float v10 = rand(p+float2(1,0));
                float v01 = rand(p+float2(0,1));
                float v11 = rand(p+float2(1,1));

                return lerp( lerp( dot( v00, f - fixed2(0,0) ), dot( v10, f - fixed2(1,0) ), u.x ),
                             lerp( dot( v01, f - fixed2(0,1) ), dot( v11, f - fixed2(1,1) ), u.x ), 
                             u.y)+0.5f;
            }
            
            float fBm (fixed2 st) 
            {
                float f = 0;
                fixed2 q = st;
                [unroll]
                for(int i = 1 ;i < 4;i++){
                    f += perlinNoise(q)/pow(2,i);
                    q = q * (2.00+i/100);
                }

                return f;
            }
            
            float4 celler3D(float3 i,float3 sepc)
            {
                float3 sep = i * sepc;
                float3 fp = floor(sep);
                float3 sp = frac(sep);
                float dist = 5.;
                float3 mp = 0.;

                [unroll]
                for (int z = -1; z <= 1; z++)
                {
                    [unroll]
                    for (int y = -1; y <= 1; y++)
                    {
                        [unroll]
                        for (int x = -1; x <= 1; x++)
                        {
                            float3 neighbor = float3(x, y ,z);
                            float3 pos = float3(random33(fp+neighbor));
                            pos = sin( (pos*6. +_Time.y/2.) )* 0.5 + 0.5;
                            float divs = length(neighbor + pos - sp);
                            mp = (dist >divs)?pos:mp;
                            dist = (dist > divs)?divs:dist;
                        }
                    }
                }
                return float4(mp,dist);
            }

            float3 celler2D(float2 i,float2 sepc)
            {
                float2 sep = i * sepc;
                float2 fp = floor(sep);
                float2 sp = frac(sep);
                float dist = 5.;
                float2 mp = 0.;

                [unroll]
                for (int y = -1; y <= 1; y++)
                {
                    [unroll]
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 neighbor = float2(x, y);
                        float2 pos = float2(random2(fp+neighbor));
                        pos = sin( (pos*6. +_Time.y/2.) )* 0.5 + 0.5;
                        float divs = length(neighbor + pos - sp);
                        mp = (dist >divs)?pos:mp;
                        dist = (dist > divs)?divs:dist;
                    }
                }
                return float3(mp,dist);
            }

            float2 Polar(float2 i)
            {
                float2 pl = 0.;
                pl.y = sqrt(i.x*i.x+i.y*i.y)*2+1;
                pl.x = atan2(i.y,i.x)/acos(-1.);
                return pl;
            }
            
            float2x2 rot(float a)
            {
                return float2x2(cos(a),sin(a),-sin(a),cos(a));
            }

            float eq(float a, float b)
            {
                return 1. - abs(sign(a - b));
            }

            struct data{
                float d; //distance
                float m; //material
                float p; //parts
                float bump; //bump
                float3 cd; //Object OBject Space
                float depth; //other
            };


            data Fish(float3 p,float scale)
            {
                p = p/scale;
                data o = (data)100;
                p.z += sin(_Time.y*2.4 + p.x * 7.)/25.; // swim
                float3 body = p;
                float3 spscale = float3(0.6,.3,1.11);
                spscale.z -= clamp(pow(1./(p.x+1.),0.17),0,1.05);
                spscale.y -= clamp(frac(-p.x + .5) * frac(-p.x + .5) /3,0.,0.2 );

                o.d = ssphere(body,spscale ,0.3);
                o.p = 0.;


                float3 erap = p;
                erap.z = -abs(erap.z);
                erap -= float3(.15,-0.01,-0.051) ;
                erap = mul(RotMat(float3(0.,0.5,0.),1.),erap);
                float era = ssphere(erap,float3(0.2,0.3,0.09) ,0.8 );


                float3 facep = p;
                facep.x -= 0.13 ;
                float3 facescale = float3(0.2,0.195,0.11);
                facescale.y -= clamp(frac(p.x * p.x*2.),0.,.09);
                facescale.z -= clamp(p.x * p.x,0.,0.06);
                float face = ssphere(facep,facescale,0.37);
                o.d = max(o.d,-era);
                o.d = min(o.d,face);
                o.p = (o.d < face)?1.:o.p;

                //o = (o.d > face)? faced:o;

                float3 eyep = p;
                
                eyep.z = abs(eyep.z);
                eyep -= float3(0.15,0.015,0.026);
                eyep.zy = mul(rot(0.2),eyep.zy);
                float eye = ssphere(eyep,float3(0.5,0.5,0.2),0.03);
                o.d = min(o.d,eye);
                o.p = (o.d < face)?2.:o.p;


                float3 bfl = p;
                bfl.xy -= float2(0.01,0.05);
                bfl.xy = mul(rot(0.2),bfl.xy);
                float l = ssphere(bfl,float3(0.2,0.07,0.01),0.51);
                float3 backfin = p;
                backfin.x -= 0.01;
                backfin.y -= 0.06;
                backfin = mul(RotMat(float3(0.,0.,1.),-4*(0.-backfin.x + backfin.y)),backfin);
                backfin.x = RepLim(backfin.x,0.02,4.);
                float bf = ssphere(backfin,float3(0.01,0.13,0.005),0.3); 
                bf = smin(l,bf,0.01);
                o.d =min(o.d,bf);
                o.p = (o.d < face)?3.:o.p;

                float3 handp = p;
                handp.z = -abs(handp.z); 
                handp += float3(-0.07,0.04,0.05);
                handp.z -= clamp( sin(Polar(handp.xy - float2(0.,0.02)).x * 40.),0.,0.1 )/100.;
                handp = mul(RotMat(float3(0.1,0.,0.),-UNITY_PI/3.),handp);
                
                handp = mul(RotMat(float3(1,1,1.),-8*(0 - handp.x + handp.y + handp.z)),handp);
                //handp.x = RepLim(handp.x,0.02,2.);
                float hand = ssphere(handp,float3(0.06,0.1,0.01),0.33); 
                o.d = min(o.d,hand) + 0.001;
                o.p = (o.d < face)?4.:o.p;
                
                float3 finp = p;
                float3 finscale = float3(0.2,0.6,0.04);
                finscale.x += clamp(finp.y ,-0.09,10.);
                finp = mul(RotMat(float3(0.,0.,1.),-finp.y*4.),finp);
                finp.x += 0.14;
                
                finp.z = abs(finp.z);
                finp.z -= clamp(sin(Polar(finp.xy - float2(0.05,0.)).x*100.)/550.,-.5,0.);
                float fin = ssphere(finp,finscale,0.2); 
                o.d = min(o.d,fin) * scale;
                o.p = (o.d < face)?5.:o.p;
                o.cd = p * scale;
                o.m = FISH;
                return o ;
            }

            data Kelp(float3 p,float scale,float offset)
            {
                p /= scale;
                data o = (data)100;
                o.m = KELP;

                float time = _Time.y/2. + offset;
                p = mul(RotMat(float3(0.,0.1,0.),(p.y)*10.),p);
                p.xz += float2(sin(p.y*10.+p.x*3.),cos(p.y*10.+p.z*3.))/30.;
                p.xz += float2(sin(p.y* 20. + time ),cos(p.y * 20. + time))/20. * c((p.y + 0.8),-1);
                float3 zikup = p;
                
                zikup.y += 0.05;
                zikup.y = RepLim(zikup.y,0.02,24.);
                float3 zikuscale = float3(0.05,0.25,0.05);

                float ziku = ssphere(zikup,zikuscale,0.3);
                o.d = ziku;
                o.p = 0.; 

                float3 hap = p;
                hap.y = RepLim(hap.y,0.02,24.);
                float3 hascale = float3(0.1,.2,0.04);
                hascale.x += S(p.y*40.)*hascale.x; 
                float ha = ssphere(hap,hascale,0.3);
                o.d = min(ha,o.d);
                o.p = step(o.d,ha);
                o.d *= scale;
                o.cd = p * scale;
                return o;
            }
            
            data Shell(float3 p,float scale)
            {
                p /= scale;
                data o = (data)100;
                
                //0~-2
                float oc = c(sin(_Time.y),.3)-1.;

                data shelld = (data)100;
                
                float3 shellpu = p-float3(0.,0.1,0.1);
                //float3 shellscale = float3(.2,.08,.2);
                //shellscale.x = clamp(shellscale.x + c(shellpo.z,-.5),0.1,1.);
                float3 shellscaleu = float3(.2,.08,.2);
                shellscaleu.x = clamp(shellscaleu.x + c(shellpu.z,-.5),0.1,1.);
                shellpu.x = abs(shellpu.x);
                shellpu.xy = mul(rot(UNITY_PI),shellpu.xy);
                
                float3 inspu = shellpu;
                inspu.y += -sin( 60. * Polar(mul(rot(-UNITY_PI/2.),shellpu.xz) - float2(.15,0.)).x ) *0.01;
                float inso = ssphere(inspu + float3(0.,0.04,0.),shellscaleu,0.6);
                
                float3 shellpo = shellpu;
                shellpo.y += sin( 70. * Polar(mul(rot(-UNITY_PI/2.),shellpo.xz) - float2(.15,0.)).x ) *0.01;
                
                shellpo.y = (shellpo.y-0.01);

                shellpu.y = (shellpu.y+0.03);
                
                float shello = ssphere(shellpo,shellscaleu,0.6);
                
                shellpu = mul(RotMat(float3(1.0,.0,.0),oc),shellpu + float3(0.,0.,0.1)) - float3(0.,0.,0.1);
                shellpu.y += sin( 70. * Polar(mul(rot(-UNITY_PI/2.),shellpu.xz) - float2(.15,0.)).x ) *0.01;
                float3 shellscaleo = float3(.2,.08,.2);
                shellscaleo.x = clamp(shellscaleo.x + c(shellpu.z,-.5),0.1,1.);
                float shellu = ssphere(shellpu,shellscaleo,0.6);
                float insu = ssphere(shellpu - float3(0.,0.04,0.),shellscaleo,0.6);
                shello = max(shello,-inso);
                shellu = max(shellu,-insu);

                float shell = min(shello,shellu);
                shelld.d = shell;
                shelld.p = 0;
                shelld.m = SHELL;
                
                o = shelld;
                o.cd = p * scale;
                return o;
            }

            data Bubble(float3 p,float scale,float speed,float ofs)
            {
                p /= scale;
                data o = (data)100.;
                o.m = BUBBLE;
                
                float t = _Time.y/10. + ofs;
                
                p.y -= t * speed;
                
                float freq = 3.;
                float id = rand( float2(0.7,0.3) * floor(p.y*freq));
                p.y = (frac(p.y*freq)-.5);
                t += id * 6.;
                
                float onoff = step(0.5,sin(id * UNITY_PI));
                p.xz += float2(1.,-1.) * sin(t + id *3.)/7.;

                float3 bscale = float3(0.1,0.1,0.1)*float3(1.,freq,1.) + dispacement(p/1.1 + _Time.y/10. + id * 6.)/80.;
                float  s = 0.5 - S(id * 10.) * 0.3;
                s *= onoff;
                o.d = ssphere(p,bscale,s) * scale;
                o.cd = p * scale;
                return o;
            }

            

            data comp(data a,data b)
            {
                data o;
                o.d = min(a.d,b.d);
                o.m = eq(a.d,o.d) * a.m + eq(b.d,o.d) * b.m;
                o.p = eq(a.d,o.d) * a.p + eq(b.d,o.d) * b.p;
                o.cd = eq(a.d,o.d) * a.cd + eq(b.d,o.d) * b.cd;
                if(eq(a.d,b.d)){return a;}
                return o;
            }

            data map(float3 p)
            {
                //p.zy = mul(rot(-UNITY_PI/2.),p.zy);
                float3 sand = p;
                float3 fish = p;
                float3 kelp = p;
                float3 shellp = p;
                float3 bubble = p;
                float scale = _FishScale;
                float kelpScale = _KelpScale;
                float ShellScale = _ShellScale;
                float bubbleScale = _BubbleScale;

                data o = (data)100;
                o.m = SAND;
                sand.y += 0.7;
               // sand.y += (0.5-vnoise(sand.xz * 3.))/10.;
                //sand.y += (0.7-vnoise(sand.xz * 6.))/10.;
                sand.y += (0.7-perlinNoise(sand.xz * 250.))/200.;
                float3 bsize = float3(10.,0.3,10.);
                bsize.y += fBm(sand.xz) - .5;
                o.d = sscube(sand,bsize);

                
                float fishid = rand(floor(fish.xz * 9.));
               // fish.xz = mod(fish.xz,9.) - 4.5;
                
                fish = mul(RotMat(float3(0.,1.,0.),-(_Time.y)/3.),fish)- float3(0.,0.,0.6);
                data fishd = Fish(fish,scale);

                data kelpd = (data)100;

                kelp.z += .7;
                
                float2 kelpid = floor(kelp.xz * .8);
                float kelpcell = perlinNoise(kelp.xz) - .5;

                float ofs = 1. * 16.1;
                kelp.y += 0.4;
                kelp.y -= (_KelpScale)/2.;

               // kelp.xz = mod(kelp.xz,.8) - 0.4;
                kelpd = Kelp(kelp,kelpScale ,ofs);
                //kelpd.d += step(.5,kelpcell);
                //kelpd.d += step(kelpcell,0.);
                
                
                data shelld = (data)100;
                shellp.y += 0.5;
                shelld = Shell(shellp,ShellScale);

                data bubbled = (data)100.;
                //bubble.xz = mod(bubble.xz,.5) - .25;
                float bofs = 0.1;
                bubbled = Bubble(bubble,bubbleScale,1.1,bofs);

                o = comp(o,fishd);
                o = comp(o,kelpd);
                o = comp(o,shelld);
                o = comp(o,bubbled);
                o.d *= .8;

                return o;
            }

            float3 calcNormal(float3 p)
            {
                float2 e = float2(0.001,0.);
                return normalize(map(p).d - float3(map(p - e.xyy).d,map( p - e.yxy).d,map( p - e.yyx).d));
            }

            bool bindbox(float3 p)
            {
                return all(max(0.5 - abs(p),float3(0.,0.,0.)));
            }

            data marching(float3 ro,float3 rd)
            {
                float depth = 0.0;
                for(int i = 0 ; i< MARCH; i++)
                {
                    float3 rp = ro + rd * depth;
                    data d = map(rp);
                    //"abs(d.d)" remove artifact
                    if(abs(d.d) < DELTA)
                    {
                        d.d = 1.0;
                        d.depth = depth;
                        return d;
                    }
                    if(abs(d.d) > 10.){break;}
                    depth += d.d;
                }
                data o = (data)-1.;
                o.depth = depth;
                return o;
            }

            data mmarching(float3 ro,float3 rd)
            {
                float depth = 0.0;
                for(int i = 0 ; i< MARCH/2.; i++)
                {
                    float3 rp = ro + rd * depth;
                    data d = map(rp);
                    //"abs(d.d)" remove artifact
                    if(abs(d.d) < DELTA)
                    {
                        d.d = 1.0;
                        d.depth = depth;
                        return d;
                    }
                    if(d.d > 16.){break;}
                    depth += d.d;
                }
                data o = (data)-1.;
                o.depth = depth;
                return o;
            }

            float4 wsurf(float3 p,float3 n)
            {
                float up = saturate(dot(n,float3(0.,1.,0.)));
                p.xz += fBm(p.xz*2. + _Time.y/10.);
                //float wsurfray = clamp( celler2D(p.xz,6.).z,0.5,1.) * 2.;
                float celler = celler3D(float3(p.x,1.,p.z),6.).w;
                float wsurfray = clamp( celler,0.5,1.) * 2.;
                return wsurfray * smoothstep(0.,1.,c(up,1.));  
            }

            float3 bg(float3 d)
            {
                float up = saturate(dot(d,float3(0.,1.,0.)));
                return up;
            }

            float dTermBeckmann(float nh, float roughness)
            {
                nh = nh * nh;
                roughness *= roughness;
                return exp((nh - 1) / (roughness * nh))/ (UNITY_PI * roughness * nh * nh);
            }

            float gTermTorrance(float nl, float nv, float nh, float vh)
            {
                return min(1 ,min(2. * nh * nv / vh,
                                  2. * nh * nl  / vh ));
            }

            float fresnelSchlick(float nv, float fresnel)
            {
                return saturate(fresnel + (1 - fresnel) * pow(1 - nv, 5));
            }

            float3 SandMaterial(data d,float3 n)
            {
                float3 color = normalize( float3(5.1,4.5,3.5) );
                return color;
            }

            float3 ShellMaterial(data d,float3 n)
            {
                float3 color = .35;
                return color;
            }

            float3 KelpMaterial(data d,float3 n)
            {
                float3 color = float3(0.,1.,0.);
                return color;
            }

            float3 FishMaterial(data d, float3 n)
            {
                float3 color = random33(float3(.1 , d.p,d.p));
                //color.gb -= step(0.,sin(length(p.x-p.z) *  100.));
                if(d.p == 2.)
                {
                    color = float3(1.,1.,1.);
                }
                return color;
            }

            float3 BubbleMaterial(data d,float3 n,float3 ro,float3 rd,float spec)
            {
                float3 color = 1.0;
                float up = saturate(dot(n,float3(0.,1.,0.)));
                color += up;

                data d1 = mmarching(ro + rd * d.depth + n + 0.01,rd);
                 float3 sandColor = SandMaterial(d1,n);
                float3 shellColor = ShellMaterial(d1,n);
                float3 kelpColor = KelpMaterial(d1,n);
                float3 fishColor = FishMaterial(d1,n);
                color = (sandColor  ) * eq(SAND,d1.m)
                       +(shellColor )  * eq(SHELL,d1.m)
                       +(kelpColor )   * eq(KELP,d1.m)
                       +(fishColor )   * eq(FISH,d1.m);
                       + spec * float3(1.,1.,1.);
                return color;
            }

            float3 render(data d,float3 ro,float3 rd,float3 cd)
            {
                float3 color = .3;
                float3 p = rd * d.depth + ro;
                float3 sun = normalize(float3(0.2,0.4,0.8));
                float3 normal = calcNormal(ro + rd * d.depth);

                if(TOON)
                {
                    normal = floor(normal * (10. + step(S(length(d.cd.y) * 990.),.5) * 900.) );
                }
                //normal = floor(normal * 10.);

                float3 view = normalize(ro - d.p);
                float3 hlf = normalize(sun + view);
                float nl = dot(normal,sun);
                float nv = dot(normal,view);
                float nh = dot(normal,hlf);
                float vh = dot(view,hlf);

                float2 rf =  float2(1.0,0.5) * eq(SAND,d.m)
                            +float2(1.0,0.5) * eq(BUBBLE,d.m)
                            +float2(1.0,0.2)  * eq(SHELL,d.m)
                            +float2(1.0,0.5)   * eq(KELP,d.m)
                            +float2(1.0,0.5)   * eq(FISH,d.m);
                float roughness = rf.x;
                float fresnel = rf.y;

                float dte = dTermBeckmann(nh , roughness);
                float gte = gTermTorrance(nl,nv,nh,vh);
                float fte = fresnelSchlick(nv,fresnel);

                float diff = 0.5 + 0.5 * saturate(dot(sun,normal));
                float spec = saturate(dte * gte * fte / (nl * nv * 4.) * nl);
                
                float surf = wsurf(p,normal);
                float2 rayspread = (perlinNoise(p.xz * 2. + float2( _Time.y,sin(_Time.z))) - .5) * float2(1.,-1.);
                float3 shadowray = normalize( (sun -  p) + float3(rayspread.x,0.,rayspread.y)/2. ) ;
                data sh = marching(p + normalize(normal) * 0.0001,shadowray);
                float shadow = sh.depth;
                
                float softshadow = smoothstep(0.,1.,shadow/10.) * .7 + .3;
                
                // float3 sandColor = SandMaterial(d,normal);
                // float3 bubbleColor = BubbleMaterial(d,normal,ro,rd);
                // float3 shellColor = ShellMaterial(d,normal);
                // float3 kelpColor = KelpMaterial(d,normal);
                // float3 fishColor = FishMaterial(d,normal);
                // color = (sandColor  ) * eq(SAND,d.m)
                //        +(bubbleColor ) * eq(BUBBLE,d.m)
                //        +(shellColor )  * eq(SHELL,d.m)
                //        +(kelpColor )   * eq(KELP,d.m)
                //        +(fishColor )   * eq(FISH,d.m);
                if(d.m == SAND){
                    color = SandMaterial(d,normal);
                }else if(d.m == BUBBLE){
                    color = BubbleMaterial(d,normal,ro,rd,spec);
                }else if(d.m == SHELL){
                    color = ShellMaterial(d,normal);
                }else if(d.m == KELP){
                    color = KelpMaterial(d,normal);
                }else{
                    color = FishMaterial(d,normal);
                }

                color *= diff * softshadow;
                color /= 2.;
                color += surf/2. * float3(.5,1.,1.) /2.;
                color += spec;
                //color = softshadow;
                //color = normal;
                //color = spec;
                color = pow(color,float3(.4545,.4545,.4545));
				//color = normalize(color);
                return color;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 ro = i.ro;
                float3 rd = normalize(i.surf - ro);
                float3 cd = -UNITY_MATRIX_V[2].xyz;

                float3 color = 0;
                data d = marching(ro,rd);
                
                clip(d.d);
                if(abs(d.d) > 0)
                {
                    color = render(d,ro,rd,cd);
                }
				float alpha = 1./clamp(d.depth,1.,25.) + (d.depth < 20.);
				alpha = saturate(alpha);
                return float4(color,alpha);
            }
            ENDCG
        }
    }
}
