shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;
render_mode specular_disabled;
//render_mode depth_prepass_alpha;
//

// direction vectors
const lowp vec3 UP 		= vec3(0,1,0);
const lowp vec3 RIGHT	= vec3(1,0,0);
const lowp vec3 FORWARD	= vec3(0,0,1);
const lowp vec3 ORIGIN	= vec3(0,0,0);

// uniforms
uniform sampler2D noise_1;
uniform sampler2D noise_2;
uniform sampler2D noise_normalmap;
uniform sampler2D water_gradient;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform float depth_max = 20.0;
uniform float animation_speed = .2;

// varying
varying float _time;
varying float _distance;
varying mat4 _camera;

// remap and clamp
float map(float value, float min1, float max1, float min2, float max2) {
 	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void vertex() {
	// compute shared variables
	_distance = distance(ORIGIN, VERTEX);
	_time     = TIME * animation_speed;
	_camera   = INV_VIEW_MATRIX;

	// normal and vertex position
	vec4 vect = vec4(VERTEX.xyz, 1.f);
	vec4 norm = -1. * vec4(FORWARD, 0.);

	// normal = Y-up
	norm.xyz = UP;
	NORMAL = norm.xyz * texture(noise_normalmap,  UV * _time).rgb;
	// UV is world position 
	UV = vect.xz / uv_scale;
	// apply vect
	VERTEX = vect.xyz;
}


void fragment()
{
	//water level
 	float height = 0.;
	// screen pixel coord
	//vec4 screen_pixel_vertex = vec4( vec3( SCREEN_UV, textureLod( DEPTH_TEXTURE, SCREEN_UV, 0.0 ).x ) * 2.0 - 1.0, 1.0 );
	//vec4 screen_pixel_coord = INV_PROJECTION_MATRIX * screen_pixel_vertex;
	//screen_pixel_coord.xyz /= screen_pixel_coord.w;
	// depth calculation
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, texture(DEPTH_TEXTURE, SCREEN_UV).x);
	vec4 world_ndc = _camera * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_depth = world_ndc.xyz / world_ndc.w;
	
	// final depth
	float depth =  mix(0.,1.,map(world_depth.y, -depth_max, depth_max, 0.,1.));
	depth = 1.f * max(0.,min(depth,1.));
	vec2 grad_uv = vec2(1.,0.) * clamp(1. - depth, 0.,1.); 
	vec4 grad_col = texture(water_gradient, grad_uv);
	vec4 water_col;
	water_col = grad_col;
	//water_col = water_grad;
	//water_col = t

	ALBEDO = water_col.rgb; //vec3(fin) + mix(alpha.rgb, col.rgb, gradientcolor.a);
	ALPHA = 1.;
	//NORMAL_MAP = texture(noise_normalmap,SCREEN_UV ).rgb;
	//ROUGHNESS = 0.9;
}