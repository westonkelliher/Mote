extends RigidBody3D

const GRAV := 9.8
const CENTER := Vector3.ZERO
@export var MOVE_FORCE := 4.0
@export var JUMP_IMPULSE := 4.0
#TODO: MOMENTUM OVERWRITE
#TODO: BOUNCE

var up := Vector3.UP
var on_floor: bool = false # now global!

func _physics_process(delta: float) -> void:
	up = (global_position-CENTER).normalized()
	var force := -up*GRAV
	apply_force(force)

func handle_move_input(input_v: Vector3) -> void:
	apply_force(input_v*MOVE_FORCE)
	
func handle_jump() -> void:
	if on_floor:
		apply_impulse(up*JUMP_IMPULSE)

###

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	on_floor = false
	for i in range(state.get_contact_count()):
		var normal := state.get_contact_local_normal(i)
		var this_contact_on_floor = normal.dot(up) > 0.2
		on_floor = on_floor or this_contact_on_floor
