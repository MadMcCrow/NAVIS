shader_type spatial;
render_mode world_vertex_coords;

// direction vectors
const lowp vec3 UP 		= vec3(0,1,0);
//const lowp vec3 RIGHT	= vec3(1,0,0);
//const lowp vec3 FORWARD	= vec3(0,0,1);
const lowp vec3 ORIGIN	= vec3(0,0,0);

// uniforms
uniform sampler2D 	noise_texture;
uniform sampler2D 	noise_normalmap;
uniform sampler2D 	noise_turbulence;
uniform sampler2D	foam_gradient;
uniform float 		foam_low  = 0.4;
uniform float 		foam_high = 0.8;
uniform float 		turbulence_amount = 0.02;
uniform float		fresnel = 0.3;
uniform vec2  		uv_scale = vec2(1.0, 1.0);
uniform float 		depth_max = 20.0;
uniform float 		animation_speed = .2;



// varying
varying float _time;
varying float _distance;
varying mat4 _camera;
varying highp float _fresnel;

// remap
float clamp_remap(float value, float min1, float max1,  float min2,float max2) {
	value = clamp(value, min1, max1);
	float retval = (min2) + ((value) - (min1)) * ((max2) - (min2)) / ((max1) - (min1));
	return clamp(retval, min2, max2);
}
// remap
vec2 remap_vec2(vec2 value, vec2 min1, vec2 max1,  vec2 min2, vec2 max2) {
	return (min2) + ((value) - (min1)) * ((max2) - (min2)) / ((max1) - (min1));
} 

vec2 turbulence(vec2 uv){
	// we just turn around a point : 
	vec2 dir = vec2(sin(_time), cos(_time));
	vec2 flow = (turbulence_amount * dir) + dir * abs(sin(_time / 10.));
	return texture(noise_turbulence,uv + flow).rg ;
}


vec3 water_fresnel(vec2 water_uv) {
	highp float noise = texture(noise_texture, water_uv).r; //noise_texture(from Viewport)
	highp float foam = smoothstep(foam_high, foam_low, noise); //foam_factor
	highp vec3 col = texture(foam_gradient, vec2(smoothstep(0.0, 1.0, noise), 0.)).rgb;
	return min(col + (0.1 * fresnel), 1.0);
}


void vertex() {
	// compute shared variables
	_distance = distance(ORIGIN, VERTEX);
	_time     = TIME * animation_speed;
	_camera   = INV_VIEW_MATRIX;
	_fresnel = sqrt(1.0 - dot(UP, CAMERA_DIRECTION_WORLD));
	// normal and vertex position
	vec4 vect = vec4(VERTEX.xyz, 1.f);
	NORMAL = UP;
	// UV is world position 
	UV = vect.xz / uv_scale;
	// apply vect
	VERTEX 		= vect.xyz;
}

vec3 world_frag_position( sampler2D depth_texture, vec2 uv, mat4 cam_inv_proj) 
{
	vec3 ndc = vec3(uv * 2.0 - 1.0, texture(depth_texture, uv).x);
	vec4 world_ndc = cam_inv_proj * vec4(ndc, 1.0);
	return world_ndc.xyz / world_ndc.w;
}

void fragment()
{
	//water level
	// TODO :
	float height = 0.;
	
	mat4 inv_proj = _camera * INV_PROJECTION_MATRIX;
	
	vec2 animated_uv = turbulence(UV); 
	// twist uv for underwater effect
	vec2 screen_water_uv = SCREEN_UV + (animated_uv / VIEWPORT_SIZE) ;
	vec2 world_water_uv  = UV        + animated_uv;
	// depth calculation
	//vec3 world_pos = world_frag_position(DEPTH_TEXTURE, SCREEN_UV, inv_proj);
	vec3 world_pos_noisy   = world_frag_position(DEPTH_TEXTURE, screen_water_uv, inv_proj);
	// make a noisy depth effect
	float mask = smoothstep(0.1, 0.9, 1. - (world_pos_noisy.y - height)); 	
	float noisy_depth = clamp_remap(world_pos_noisy.y, -depth_max, 0., 0.,1.) * mask ;
	
	// color from objects below
	vec3 original_color = texture(SCREEN_TEXTURE, screen_water_uv).rgb;
	vec3 top_color   = water_fresnel(world_water_uv);
	vec3 trans_color = mix(top_color, original_color, clamp(noisy_depth, 0.,1));
	// mix-in
	ALBEDO = trans_color; // (top_color + trans_color)/2.0;
	NORMAL_MAP = texture(noise_normalmap,animated_uv).rgb;
	//ROUGHNESS = 0.8;
}