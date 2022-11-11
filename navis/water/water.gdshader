shader_type spatial;

// water noise
uniform sampler2D noise;

const vec3 RIGHT	= vec3(1.f,0.f,0.f);
const vec3 UP 		= vec3(0.f,1.f,0.f);
const vec3 UP_MASK	= vec3(1.f,0.f,1.f);

varying vec2 tex_position;

mat4 rotation_matrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    mat4 matrix;
	matrix[0] = vec4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0);
    matrix[1] = vec4(oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0);
    matrix[2] = vec4(oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0);
	matrix[3] = vec4(0.0,                                0.0,                                0.0,                                1.0);
	return matrix;
}

vec4 rotate(vec4 vector, vec3 axis, float angle)
{
	axis = normalize(axis);
	return rotation_matrix(axis, angle) * vector;
}

vec3 project_to_y(vec3 position, vec3 vector) {
	float delta 	= -position.y / vector.y;
	return position + delta * vector;
}

float wave(vec2 world_pos)
{
	return 0.f;
}

void vertex() {
	// view infos :
	//float fov    = 2.0 * atan( 1.0 / PROJECTION_MATRIX[1][1] ); // * 180.0 / PI;
	//float aspect =  PROJECTION_MATRIX[1][1] / PROJECTION_MATRIX[0][0];
    // go to vec4 for operations
	vec4 pos = vec4(VERTEX,1.f);
	// Wave effect
	vec3 world_pos = (pos * MODEL_MATRIX).xyz;
	float height   = wave(world_pos.xz); // y is up    
	// get angle with camera
	vec3 cam_forward = normalize((vec4(0.f,0.f,1.f,1.f) * VIEW_MATRIX).xyz);
	vec3 forward     = normalize(cam_forward.xyz * UP_MASK);
	float theta      = acos(dot(cam_forward, forward));
	// adapt to screen
	pos *= VIEW_MATRIX;
	pos = rotate(pos,RIGHT,-1.f * theta);ds
	//pos *= PROJECTION_MATRIX;
	pos.xyz = pos.zyx;
	// apply to vertex
	VERTEX = pos.xyz;
	VERTEX.y += height;
}

void fragment() {
	// NORMALMAP = texture(normalmap, tex_position).xyz;
}
