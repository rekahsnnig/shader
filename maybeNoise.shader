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

            //https://www.shadertoy.com/view/XsX3zB
            /* skew constants for 3d simplex functions */
            const float F3 =  0.3333333;
            const float G3 =  0.1666667;
            
            /* 3d simplex noise */
            float simplex3d(float3 p) {
                /* 1. find current tetrahedron T and it's four vertices */
                /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
                /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
                
                /* calculate s and x */
                float3 s = floor(p + dot(p, float3(F3,F3,F3)));
                float3 x = p - s + dot(s, float3(G3,G3,G3));
                
                /* calculate i1 and i2 */
                float3 e = step(float3(0.,0.,0.), x - x.yzx);
                float3 i1 = e*(1.0 - e.zxy);
                float3 i2 = 1.0 - e.zxy*(1.0 - e);
                    
                /* x1, x2, x3 */
                float3 x1 = x - i1 + G3;
                float3 x2 = x - i2 + 2.0*G3;
                float3 x3 = x - 1.0 + 3.0*G3;
                
                /* 2. find four surflets and store them in d */
                float4 w, d;
                
                /* calculate surflet weights */
                w.x = dot(x, x);
                w.y = dot(x1, x1);
                w.z = dot(x2, x2);
                w.w = dot(x3, x3);
                
                /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
                w = max(0.6 - w, 0.0);
                
                /* calculate surflet components */
                d.x = dot(random3(s), x);
                d.y = dot(random3(s + i1), x1);
                d.z = dot(random3(s + i2), x2);
                d.w = dot(random3(s + 1.0), x3);
                
                /* multiply d by w^4 */
                w *= w;
                w *= w;
                d *= w;
                
                /* 3. return the sum of the four surflets */
                return dot(d, float4(52.0,52.0,52.0,52.0));
            }

            float3 simplex3dVector(float3 p)
            {
                float s = simplex3d(p);
                float s2 = simplex3d(random3(float3(p.y,p.x,p.z)) + p.yxz);
                float s3 = simplex3d(random3(float3(p.z,p.y,p.x)) + p.zyx);
                return float3(s,s2,s3);
            }

             float3 random33(float3 st)
            {
                st = float3(dot(st, float3(127.1, 311.7,811.5)),
                            dot(st, float3(269.5, 183.3,211.91)),
                            dot(st, float3(511.3, 631.19,431.81))
                            );
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
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

            float3 curlNoiseSimp(float3 p)
            {
                float3 e = float3(0.0001,0.,0.);

                float3 x1 = simplex3dVector(p - e);
                float3 x2 = simplex3dVector(p + e);
                float3 y1 = simplex3dVector(p - e.yxz);
                float3 y2 = simplex3dVector(p + e.yxz);
                float3 z1 = simplex3dVector(p - e.zyx);
                float3 z2 = simplex3dVector(p - e.zyx);

                float x = y2.z - y1.z - z2.y + z1.y;
                float y = z2.x - z1.x - x2.z + x1.z;
                float z = x2.y - x1.y - y2.x + y1.x;

                return normalize(float3(x,y,z)/2.*e.x);
            }

            float3 curlNoiseCell(float3 p,float s)
            {
                float3 e = float3(0.0001,0.,0.);

                float3 x1 = celler3D(p - e,s).xyz;
                float3 x2 = celler3D(p + e,s).xyz;
                float3 y1 = celler3D(p - e.yxz,s).xyz;
                float3 y2 = celler3D(p + e.yxz,s).xyz;
                float3 z1 = celler3D(p - e.zyx,s).xyz;
                float3 z2 = celler3D(p - e.zyx,s).xyz;

                float x = y2.z - y1.z - z2.y + z1.y;
                float y = z2.x - z1.x - x2.z + x1.z;
                float z = x2.y - x1.y - y2.x + y1.x;

                return normalize(float3(x,y,z)/2.*e.x);
            }
            
            
            
            
            
            
                        vec3 random3(vec3 c) {
                float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
                vec3 r;
                r.z = fract(512.0*j);
                j *= .125;
                r.x = fract(512.0*j);
                j *= .125;
                r.y = fract(512.0*j);
                return r-0.5;
            }

            //https://www.shadertoy.com/view/XsX3zB
            /* skew constants for 3d simplex functions */
            const float F3 =  0.3333333;
            const float G3 =  0.1666667;
            
            /* 3d simplex noise */
            float simplex3d(vec3 p) {
                /* 1. find current tetrahedron T and it's four vertices */
                /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
                /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
                
                /* calculate s and x */
                vec3 s = floor(p + dot(p, vec3(F3,F3,F3)));
                vec3 x = p - s + dot(s, vec3(G3,G3,G3));
                
                /* calculate i1 and i2 */
                vec3 e = step(vec3(0.,0.,0.), x - x.yzx);
                vec3 i1 = e*(1.0 - e.zxy);
                vec3 i2 = 1.0 - e.zxy*(1.0 - e);
                    
                /* x1, x2, x3 */
                vec3 x1 = x - i1 + G3;
                vec3 x2 = x - i2 + 2.0*G3;
                vec3 x3 = x - 1.0 + 3.0*G3;
                
                /* 2. find four surflets and store them in d */
                float4 w, d;
                
                /* calculate surflet weights */
                w.x = dot(x, x);
                w.y = dot(x1, x1);
                w.z = dot(x2, x2);
                w.w = dot(x3, x3);
                
                /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
                w = max(0.6 - w, 0.0);
                
                /* calculate surflet components */
                d.x = dot(random3(s), x);
                d.y = dot(random3(s + i1), x1);
                d.z = dot(random3(s + i2), x2);
                d.w = dot(random3(s + 1.0), x3);
                
                /* multiply d by w^4 */
                w *= w;
                w *= w;
                d *= w;
                
                /* 3. return the sum of the four surflets */
                return dot(d, float4(52.0,52.0,52.0,52.0));
            }

            vec3 simplex3dVector(vec3 p)
            {
                float s = simplex3d(p);
                float s2 = simplex3d(random3(vec3(p.y,p.x,p.z)) + p.yxz);
                float s3 = simplex3d(random3(vec3(p.z,p.y,p.x)) + p.zyx);
                return vec3(s,s2,s3);
            }

             vec3 random33(vec3 st)
            {
                st = vec3(dot(st, vec3(127.1, 311.7,811.5)),
                            dot(st, vec3(269.5, 183.3,211.91)),
                            dot(st, vec3(511.3, 631.19,431.81))
                            );
                return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
            }

            float4 celler3D(vec3 i,vec3 sepc)
            {
                vec3 sep = i * sepc;
                vec3 fp = floor(sep);
                vec3 sp = fract(sep);
                float dist = 5.;
                vec3 mp = 0.;

                [unroll]
                for (int z = -1; z <= 1; z++)
                {
                    [unroll]
                    for (int y = -1; y <= 1; y++)
                    {
                        [unroll]
                        for (int x = -1; x <= 1; x++)
                        {
                            vec3 neighbor = vec3(x, y ,z);
                            vec3 pos = vec3(random33(fp+neighbor));
                            pos = sin( (pos*6. +_Time.y/2.) )* 0.5 + 0.5;
                            float divs = length(neighbor + pos - sp);
                            mp = (dist >divs)?pos:mp;
                            dist = (dist > divs)?divs:dist;
                        }
                    }
                }
                return float4(mp,dist);
            }
            
            float2 random2(float2 c) {
                float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
                float2 r;
                r.x = frac(512.0*j);
                j *= .125;
                r.y = frac(512.0*j);
                return r-0.5;
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

            vec3 curlNoiseSimp(vec3 p)
            {
                vec3 e = vec3(0.0001,0.,0.);

                vec3 x1 = simplex3dVector(p - e);
                vec3 x2 = simplex3dVector(p + e);
                vec3 y1 = simplex3dVector(p - e.yxz);
                vec3 y2 = simplex3dVector(p + e.yxz);
                vec3 z1 = simplex3dVector(p - e.zyx);
                vec3 z2 = simplex3dVector(p - e.zyx);

                float x = y2.z - y1.z - z2.y + z1.y;
                float y = z2.x - z1.x - x2.z + x1.z;
                float z = x2.y - x1.y - y2.x + y1.x;

                return normalize(vec3(x,y,z)/2.*e.x);
            }

            vec3 curlNoiseCell(vec3 p,float s)
            {
                vec3 e = vec3(0.0001,0.,0.);

                vec3 x1 = celler3D(p - e,s).xyz;
                vec3 x2 = celler3D(p + e,s).xyz;
                vec3 y1 = celler3D(p - e.yxz,s).xyz;
                vec3 y2 = celler3D(p + e.yxz,s).xyz;
                vec3 z1 = celler3D(p - e.zyx,s).xyz;
                vec3 z2 = celler3D(p - e.zyx,s).xyz;

                float x = y2.z - y1.z - z2.y + z1.y;
                float y = z2.x - z1.x - x2.z + x1.z;
                float z = x2.y - x1.y - y2.x + y1.x;

                return normalize(vec3(x,y,z)/2.*e.x);
            }
