@tool
extends MeshInstance3D

@export var water_script : Script

# water 4 corners
@onready var wlt = Vector3()
@onready var wlb = Vector3()
@onready var wrt = Vector3()
@onready var wrb = Vector3()

# find the coresponding world position
func _raycast_point(camera : Camera3D, screen_pos : Vector2) :
	var N = camera.project_ray_normal(screen_pos) # camera normal vector for pos
	var A = camera.project_ray_origin(screen_pos) # position of "camera" point pos
	if N.dot(Vector3.UP) <= 0 :
		var fact = abs(A.y / N.y) # because A.y + Fact * N.y = 0 (we know y will be 0)
		return Vector3(A.x + fact * N.x, 0.0, A.z + fact * N.z)
	var fact = abs(camera.far - 20)
	return (A + (N * fact)) * Vector3(1.0,0.0,1.0)

# called by the physics tick
func _physics_process(_delta) : 
	var viewport = get_viewport()
	var size     = viewport.get_visible_rect().size;
	var camera   = viewport.get_camera_3d()
	if camera == null :
		return
	# get coordinates in world space of 4 corners
	var screen_mid = _raycast_point(camera, Vector2.ZERO) # get far out in front
	var camera_mid = camera.unproject_position(screen_mid) * Vector2(0.0,1.0); # unproject to get the equivalent on screen
	# find water plane : use middle to avoid misaligned camera issues
	wlt = _raycast_point(camera,camera_mid)
	wrt = _raycast_point(camera,camera_mid + Vector2(size.x, 0))
	# we assume bottom of screen is water
	wlb = _raycast_point(camera, Vector2(0,size.y))
	wrb = _raycast_point(camera, Vector2(size.x,size.y))

func init_mesh() :
	mesh = ArrayMesh.new()
	mesh.set_script(water_script)
	mesh.init()

func _ready():
	init_mesh()

func _process(_delta):
	if mesh == null :
		init_mesh()
	mesh.set_points(wlb, wlt, wrb, wrt)
	mesh.immediate_frame()

