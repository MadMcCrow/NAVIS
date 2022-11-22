shader_type spatial;

// coordinates are world-space
render_mode world_vertex_coords;

// inputs
uniform sampler2D col_gradient_foam;
uniform sampler2D col_gradient_water;

uniform int octave 				 = 6;
uniform lowp float mulscale		 = 5.0;
uniform lowp float height		 = 0.6;
uniform lowp float tide			 = 0.1;
uniform lowp float foamthickness = 0.1;
uniform lowp float timescale	 = 1.0;
uniform lowp float waterdeep	 = 0.3;
uniform lowp vec3  seed			 = vec3(.23,44.,253.);

// random-ish function
float rand(vec2 input){
	return fract(sin(dot(input,seed.xy))*seed.z);
}

// perlin noise
float perlin(vec2 input){
	vec2 i = floor(input);
	vec2 j = fract(input);
	vec2 coord = smoothstep(0.,1.,j);
	float a = rand(i);
	float b = rand(i+vec2(1.0,0.0));
	float c = rand(i+vec2(0.0,1.0));
	float d = rand(i+vec2(1.0,1.0));
	return mix(mix(a,b,coord.x),mix(c,d,coord.x),coord.y);
}

float fbm(vec2 input){
	float value = 0.0;
	float scale = 0.5;
	for(int i = 0; i < octave; i++){
		value += perlin(input)*scale;
		input*=2.0;
		scale*=0.5;
	}
	return value;
}

// no need, we just override UV
// varying highp vec3 world_pos;

void vertex(){
	vec4 world_vert = vec4(VERTEX, 0.);
	// world_pos = world_vert.xyz;
	UV = world_vert.xz;
}

void fragment(){
	//UV = world_pos.xz;
	// calc effects
	float stime = TIME*timescale;
	float fbmval = fbm(vec2(UV.x*mulscale+0.2*sin(0.3*stime)+0.15*stime,-0.05*stime+UV.y*mulscale+0.1*cos(0.68*stime)));
	float fbmvalshadow = fbm(vec2(UV.x*mulscale+0.2*sin(-0.6*stime + 25.0 * UV.y)+0.15*stime+3.0,-0.05*stime+UV.y*mulscale+0.13*cos(-0.68*stime))-7.0+0.1*sin(0.43*stime));
	float myheight = height+tide*sin(stime+5.0*UV.x-8.0*UV.y);
	float shadowheight = height+tide*1.3*cos(stime+2.0*UV.x-2.0*UV.y);
	float withinFoam = step(myheight, fbmval)*step(fbmval, myheight + foamthickness);
	float shadow = (1.0-withinFoam)*step(shadowheight, fbmvalshadow)*step(fbmvalshadow, shadowheight + foamthickness * 0.7);
	// sample colors
	float foam_time = sin(pow(stime * 0.001,2));
	vec3  foam_col = texture(col_gradient_foam, vec2(foam_time,0.f)).rgb;
	float water_time = sin(pow(stime * 0.002,2));
	vec3  water_col = texture(col_gradient_water, vec2(water_time,0.f)).rgb;
	float water2_time = sin(pow(stime * 0.002,2));
	vec3  water2_col = texture(col_gradient_water, vec2(water2_time,0.f)).rgb;
	// apply ALBEDO
	ALBEDO = withinFoam*foam_col + shadow*water2_col + ((1.0-withinFoam)*(1.0-shadow))*water_col;
	
}