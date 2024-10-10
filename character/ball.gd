extends RigidBody3D

const GRAV := 9.8
const CENTER := Vector3.ZERO
#
@export var BOUNCE := 0.5 :
	set(value):
		BOUNCE = value
		physics_material_override.bounce = value
	get:
		return BOUNCE
@export var FRICTION := 1.0 :
	set(value):
		FRICTION = value
		physics_material_override.friction = value
	get:
		return FRICTION
#
@export var COYOTE_TIME := 0.2 :
	set(value):
		COYOTE_TIME = value
		if !has_node("CoyoteTimer"):
			return
		$CoyoteTimer.wait_time = value
		$JumpTimer.wait_time = value
	get:
		return COYOTE_TIME
#
@export var GROUND_MOVE_FORCE := 20.0
@export var AIR_MOVE_FORCE := 8.0
@export var MOVE_FORCE_HALFLIFE := 1.5
@export var JUMP_IMPULSE := 4.0
@export var MOMENTUM_OVERWRITE := 0.8


var up := Vector3.UP
var on_floor: bool = false
var frames_since_jump = 0
var has_hit_floor_since_jump = false

func _ready() -> void:
	FRICTION = FRICTION
	BOUNCE = BOUNCE
	COYOTE_TIME = COYOTE_TIME

func _physics_process(delta: float) -> void:
	up = (global_position-CENTER).normalized()
	var force := -up*GRAV
	apply_force(force)

func handle_move_input(input_v: Vector3) -> void:
	var mfhl := MOVE_FORCE_HALFLIFE
	var base_move_force := GROUND_MOVE_FORCE
	if !on_floor:
		base_move_force = AIR_MOVE_FORCE
	var move_force := base_move_force*(mfhl/(linear_velocity.length()+mfhl))
	# movement overwrite (slow down faster)
	var vert_vel := up*linear_velocity.dot(up)
	var lat_vel := linear_velocity - vert_vel
	var agreement := 0.5 * (1.0 + input_v.dot(lat_vel.normalized()))
	var disagreement := 1.0 - agreement
	var overwrite_force := move_force*(disagreement)*MOMENTUM_OVERWRITE
	apply_force(-linear_velocity.normalized()*overwrite_force)
	apply_force(input_v*overwrite_force)
	#
	apply_force(input_v * move_force)
	
func handle_jump() -> void:
	if on_floor and has_hit_floor_since_jump:
		apply_impulse(up*JUMP_IMPULSE)
		frames_since_jump = 0
		has_hit_floor_since_jump = false

###

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#on_floor = false
	for i in range(state.get_contact_count()):
		var normal := state.get_contact_local_normal(i)
		var this_contact_on_floor = normal.dot(up) > 0.2
		if this_contact_on_floor:
			if frames_since_jump > 1:
				has_hit_floor_since_jump = true
			on_floor = true
			$CoyoteTimer.start()
	#
	frames_since_jump += 1


func _on_coyote_timer_timeout() -> void:
	on_floor = false
