shader_type spatial;
render_mode world_vertex_coords;
render_mode depth_prepass_alpha;
render_mode unshaded;

// direction vectors
const lowp vec3 UP 		= vec3(0,1,0);
const lowp vec3 RIGHT	= vec3(1,0,0);
const lowp vec3 FORWARD	= vec3(0,0,1);
const lowp vec3 ORIGIN	= vec3(0,0,0);

// uniforms
uniform sampler2D water_noise_texture;
uniform sampler2D water_noise_normalmap;
uniform sampler2D water_noise_uv;
uniform sampler2D water_gradient;
uniform float water_uv_amount = 0.02;
uniform vec3 water_color;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform float depth_max = 20.0;
uniform float animation_speed = .2;
uniform float foam_low  = 0.4;
uniform float foam_high = 0.8;


// varying
varying float _time;
varying float _distance;
varying mat4 _camera;
varying highp float _fresnel;

// remap and clamp
vec3 map_vec3(vec3 value, float min1, float max1, float min2, float max2) {
 	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
vec2 map_vec2(vec2 value, float min1, float max1, float min2, float max2) {
 	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
float map(float value, float min1, float max1, float min2, float max2) {
 	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}


vec3 water_fresnel(vec2 water_uv , float fresnel) {
	mediump vec3 noise = texture(water_noise_texture, water_uv).rgb; //noise_texture(from Viewport)
	mediump vec3 foam = smoothstep(vec3(foam_high), vec3(foam_low), noise); //foam_factor
	// todo : replace by gradient 
	mediump vec3 col_1 = vec3(0.0, 0.1, 0.3);
	mediump vec3 col_2 = vec3(0.1, 0.3, 0.4);
	mediump vec3 col_3 = vec3(0.4, 0.8, 0.8);
	mediump vec3 col_4 = vec3(0.8, 0.9, 0.9);
	mediump vec3 col = mix(
		mix(col_1, col_2, noise*0.6),
		mix(col_3, col_4, noise*1.2),
		smoothstep(0.0, 1.0, noise));
	mediump vec3 fCol = clamp(mix(vec3(0.999), col, foam), 0.0, 1.0); //final_color
	
	//ALBEDO = min(fCol + (0.1 * fresnel), 1.0);
	//SPECULAR = 0.2 * fresnel;
	//ROUGHNESS = mix(0.9, 0.7, fFac.z) * (1.0 - fresnel*0.2);
	//TRANSMISSION = vec3(0.2, 0.7, 0.3);
	return min(fCol + (0.1 * fresnel), 1.0);
}

void vertex() {
	// compute shared variables
	_distance = distance(ORIGIN, VERTEX);
	_time     = TIME * animation_speed;
	_camera   = INV_VIEW_MATRIX;
	_fresnel = sqrt(1.0 - dot(UP, CAMERA_DIRECTION_WORLD));

	// normal and vertex position
	vec4 vect = vec4(VERTEX.xyz, 1.f);
	NORMAL = UP * texture(water_noise_normalmap,  UV * _time).rgb;
	// UV is world position 
	UV = vect.xz / uv_scale;
	// apply vect
	VERTEX 		= vect.xyz;
	
}

vec3 world_frag_position( sampler2D depth_texture, vec2 uv, mat4 cam_inv_proj) 
{
	vec3 ndc = vec3(uv * 2.0 - 1.0, texture(depth_texture, uv).x);
	vec4 world_ndc = _camera * cam_inv_proj * vec4(ndc, 1.0);
	return world_ndc.xyz / world_ndc.w;
}


void fragment()
{
	//water level
	float height = 0.;
	// twist uv for underwater effect
	vec2 water_uv = SCREEN_UV;
	water_uv += water_uv_amount * map_vec2(texture(water_noise_uv, SCREEN_UV).rg, 0.,1.,-0.5,.0);

	// depth calculation
	vec3 original_depth = world_frag_position(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 offset_depth   = world_frag_position(DEPTH_TEXTURE, water_uv,  INV_PROJECTION_MATRIX);
	
	float depth =  map(original_depth.y, -depth_max, 0., 0.,1.); 	
	float noisy_depth = map(offset_depth.y, -depth_max, 0., 0.,1.);
	
	// color from objects below
	vec3 original_color = texture(SCREEN_TEXTURE, water_uv).rgb;
	
	// mix-in
	ALBEDO = vec3(noisy_depth); // mix(water_color, original_color, clamp(depth, 0.,1));
	ALPHA = 1.;
	//SPECULAR = 0.2 * _fresnel;
	//NORMAL_MAP = texture(noise_normalmap,UV).rgb;
	ROUGHNESS = 0.8;
}