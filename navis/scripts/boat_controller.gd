extends Node

## Setup variables
# physics controls
@export var boat_body    : RigidBody3D
# inputs
@export var input_forward    : StringName
@export var input_backward   : StringName
@export var input_right      : StringName
@export var input_left       : StringName
@export var input_fire       : StringName
@export var input_threshold  : float
# camera
@export var camera_node      : Camera3D
@export var camera_min_angle : float
@export var camera_max_angle : float
@export var camera_speed     : float

func process_input(event : InputEvent, event_name : StringName, function, factor : float) :
	var amount = event.get_action_strength(event_name)
	if amount >= input_threshold :
		function.call(amount * factor)

# add movement impulse
func _move_input(amount : float) :
	boat_body.move(amount)
	
# fire at will !
func _fire(_amount : float) :
	pass
	
# turn ship ?
# -1 is left, 1 is right
func _turn_input(amount : float) :
	boat_body.turn(amount)

# process inputs for the player
func _input(event):
	# ignore release 
	if event is InputEventKey and not event.is_pressed():
		return
	process_input(event, input_forward,  _move_input,  1.)
	process_input(event, input_backward, _move_input, -1.)
	process_input(event, input_right, 	 _turn_input,  1.)
	process_input(event, input_left,  	 _turn_input, -1.)
	
