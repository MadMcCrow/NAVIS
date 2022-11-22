extends RigidBody3D

# physics values
@export var max_speed         : float = 10.
@export var acceleration      : float = 10.
@export var turn_max_speed    : float = 1.
@export var turn_acceleration : float = 1.

const forward_vector = Vector3(0,0,1)
const right_vector   = Vector3(1,0,0)
const up_vector      = Vector3(0,1,0)
const origin_vector  = Vector3(0,0,0)

# add force at direction over time
var direction
var force

# move forward
func move(force : float) :
	var basis       = get_transform().basis
	var pos_local   = basis * origin_vector
	var force_local = basis * forward_vector
	apply_impulse(force_local * force * acceleration, pos_local)

# turn the boat
func turn(force : float):
	apply_torque_impulse(up_vector * force * turn_acceleration * -1.)

# limit boat velocity to max speed
func _clamp_velocity(velocity : Vector3, max : float) :
	var length = velocity.length()
	if length > max :
		return (velocity / length) * min(length, max_speed)
	return velocity

func _physics_process(_delta):
	set_linear_velocity(_clamp_velocity(get_linear_velocity(), max_speed))
	set_angular_velocity(_clamp_velocity(get_angular_velocity(), turn_max_speed))
