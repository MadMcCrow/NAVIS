extends ArrayMesh

# Points for the array
@onready var vertices = PlaneMesh.new().get_mesh_arrays();
# tool for editing points
@onready var tool = MeshDataTool.new();

# Set points with data
func set_points(_a : Vector3, _b : Vector3, _c : Vector3, _d: Vector3):
	vertices = [_a, _b, _c, _d]
	
func _ready() :
	add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,  PlaneMesh.new().get_mesh_arrays())

# render function
func immediate_frame():
	var error = tool.create_from_surface(self, 0)
	if error != OK:
		printerr("Failure!")
		return
	clear_surfaces()
	for i in range(vertices.size()):
		tool.set_vertex_normal(i, Vector3.UP)
		tool.set_vertex(i, vertices[i])
	tool.commit_to_surface(self)


