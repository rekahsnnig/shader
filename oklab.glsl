float cbrt(float a) {
	float e;
    float x = 3.;
  	for(int i = 0;i<33;i++){
    	e = (x * x * x - a) / (3. * x * x);
    	x = x - e;
    	if(abs(e) > 1e-16)break;
  	}
  return x;
}

vec3 rgb2oklab(vec3 c) 
{
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
	float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
	float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;

    float ll = cbrt(l);
    float mm = cbrt(m);
    float ss = cbrt(s);

    return vec3(
        0.2104542553*ll + 0.7936177850*mm - 0.0040720468*ss,
        1.9779984951*ll - 2.4285922050*mm + 0.4505937099*ss,
        0.0259040371*ll + 0.7827717662*mm - 0.8086757660*ss
    );
}

vec3 oklab2rgb(vec3 c) 
{
    float ll = c.x + 0.3963377774 * c.y + 0.2158037573 * c.z;
    float mm = c.x - 0.1055613458 * c.y - 0.0638541728 * c.z;
    float ss = c.x - 0.0894841775 * c.y - 1.2914855480 * c.z;

    float l = ll*ll*ll;
    float m = mm*mm*mm;
    float s = ss*ss*ss;

    return vec3(
		4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    );
}
