extends Node3D

#
@export var MOUSE_SENSITIVITY := 0.0055
@export var ROTATION_SPEED := 12.0
#
@export var STICK_CAM_LAT_SPEED := 5.0
@export var STICK_CAM_PITCH_SPEED := 1.8
# TODO: stick_cam_acc




var ball: Node = null
var target_cam_pitch := 0.0

func _ready() -> void:
	ball = $Ball
	var detach := Node.new()
	add_child(detach)
	remove_child(ball)
	detach.add_child(ball)
	ball.global_position = global_position

func _physics_process(delta: float) -> void:
	global_position = ball.global_position
	#
	handle_move_input(delta)
	handle_joystick_camera_move(delta)
	stand_right_up(delta, 1.0)


func handle_move_input(delta: float) -> void:
	# jumping
	if Input.is_action_just_pressed("jump"):
		ball.handle_jump()
	# stick
	var input_dir := input_dir()
	if input_dir.length() == 0.0:
		return
	#
	var global_input_dir := global_basis * input_dir()
	ball.handle_move_input(global_input_dir)
	#
	var temp: float = $SpringArm.rotation.y
	$SpringArm.rotation.y = lerp_angle($SpringArm.rotation.y, 0.0, ROTATION_SPEED * delta)
	var rotated_amount: float = $SpringArm.rotation.y - temp
	basis = basis.rotated(basis * Vector3.UP, -rotated_amount)

func handle_joystick_camera_move(delta: float) -> void:
	var gpi := InputHandler.get_gamepad_input()
	var stick := gpi.stick_R
	$SpringArm.rotation.y -= stick.x * STICK_CAM_LAT_SPEED * delta
	$SpringArm.rotation.x += stick.y * STICK_CAM_PITCH_SPEED * delta
	$SpringArm.rotation_degrees.x = clamp($SpringArm.rotation_degrees.x, -90.0, 30.0)
	#target_cam_pitch = clamp(stick.y * PI/2, -PI/4, PI/2.1)
	#var pitch_amnt := STICK_CAM_PITCH_SPEED * delta
	#$SpringArm.rotation.x  = move_toward($SpringArm.rotation.x, target_cam_pitch, pitch_amnt)
	# TODO: use target rotation.x and lerp towards it

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$SpringArm.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		$SpringArm.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		$SpringArm.rotation_degrees.x = clamp($SpringArm.rotation_degrees.x, -90.0, 30.0)


func input_dir() -> Vector3:
	var input_dir := Vector3.ZERO
	# gamepad
	var gpi := InputHandler.get_gamepad_input()
	if !gpi.is_nothing():
		input_dir.x = gpi.stick_L.x
		input_dir.z = -gpi.stick_L.y
		return input_dir
	# keyboard
	input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_dir.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
	return input_dir.normalized()


# rotate about the feet
func stand_right_up(delta: float, flooriness: float) -> void:
	# basis
	var forward: Vector3 = transform.basis[2]
	var down: Vector3 = -global_position.normalized()
	var right: Vector3 = forward.cross(down).normalized()
	if down.dot(basis * Vector3.UP) > 0:
		basis = basis.rotated(Vector3(1, 1, 1).normalized(), 0.01)
	# Recalculate forward to ensure it's orthogonal
	forward = down.cross(right).normalized()
	# Create rotation basis
	var target_basis: Basis = Basis(right, -down, forward).orthonormalized()
	# rotate the player to the target rotation
	var mult := 5 * (basis*Vector3.DOWN - down).length() * flooriness
	var a := transform.basis[0].move_toward(target_basis[0], mult*delta)
	var b := transform.basis[1].move_toward(target_basis[1], mult*delta)
	var c := transform.basis[2].move_toward(target_basis[2], mult*delta)
	basis = Basis(a, b, c).orthonormalized()
	#velocity += basis * Vector3.UP * 0.01 * delta
		
		
