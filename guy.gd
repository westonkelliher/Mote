extends CharacterBody3D

const CENTER := Vector3.ZERO

@export var GROUND_ACC := 12.0
@export var AIR_ACC := 4.0
@export var GROUND_BRAKE := 0.5
@export var AIR_BRAKE := 0.1
@export var JUMP_VELOCITY := 5.0
@export var SPEED := 5.0
@export var FLOOR_STICK := 1.7
@export var GRAVITY := 15.0

var input_dir := Vector3.ZERO
var on_floor := 0.0
var vert_velocity := Vector3.ZERO
var lat_velocity := Vector3.ZERO
var is_jumping := false

func _process(delta: float) -> void:
	$Sprite2D/Sprite2D.scale.x = velocity.dot(up_direction)

func _physics_process(delta: float) -> void:
	orient()
	check_floor()
	move_from_input(delta)
	apply_gravity(delta)
	#
	apply_velocities(delta)
	#
	if !is_on_floor():
		is_jumping = false


func apply_velocities(delta: float) -> void:
	#velocity = vert_velocity + lat_velocity
	move_and_slide()
	#vert_velocity = up_direction * velocity.dot(up_direction)
	#lat_velocity = velocity - vert_velocity

func orient() -> void:
	up_direction = (global_position - CENTER).normalized()
	basis = get_parent().get_parent().basis

func apply_gravity(delta: float) -> void:
	velocity += -up_direction * GRAVITY * delta
	#if is_on_floor() and !is_jumping:
		#pass#vert_velocity = vert_velocity.move_toward(-up_direction*FLOOR_STICK, 3.0*GRAVITY*delta)
	#else:
		#vert_velocity += -up_direction * GRAVITY * delta
	# TODO: always apply gravity just remove part of vel that is normal when touching floor

func check_floor() -> void:
	if is_on_floor() and !is_jumping:
		on_floor = 1.0
		$CoyoteTimer.start()
	else:
		on_floor = $CoyoteTimer.time_left/$CoyoteTimer.wait_time

func move_from_input(delta: float) -> void:
	if input_dir.length() == 0.0:
		if is_on_floor():
			floor_brake(delta)#*on_floor)
		else:
			air_brake(delta)
		#air_brake(delta*(1.0-on_floor))
		return
	vert_velocity = up_direction * velocity.dot(up_direction)
	lat_velocity = velocity - vert_velocity
	if on_floor == 0.0:
		lat_velocity = lat_velocity.move_toward(input_dir*SPEED, AIR_ACC*delta)
	else:
		lat_velocity = lat_velocity.move_toward(input_dir*SPEED, GROUND_ACC*delta)
	velocity = vert_velocity + lat_velocity

func floor_brake(delta: float) -> void:
	velocity *= pow((1.0-GROUND_BRAKE), delta)
	velocity = velocity.move_toward(Vector3.ZERO, GROUND_ACC * delta)

func air_brake(delta: float) -> void:
	velocity *= pow((1.0-AIR_BRAKE), delta)


###

func handle_move_input(input_v: Vector3) -> void:
	input_dir = input_v
	
func handle_jump() -> void:
	if on_floor > 0.0:
		velocity *= 0.1
		velocity += up_direction*JUMP_VELOCITY * on_floor
		is_jumping = true
		on_floor = 0.0

###

func _on_coyote_timer_timeout() -> void:
	on_floor = false
