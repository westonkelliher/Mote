extends Node3D

@export var MOUSE_SENSITIVITY := 0.0055
@export var ROTATION_SPEED := 12.0

var ball: Node = null

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$SpringArm.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		$SpringArm.rotation_degrees.x = clamp($SpringArm.rotation_degrees.x, -90.0, 30.0)
		$SpringArm.rotation.y -= event.relative.x * MOUSE_SENSITIVITY


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
		
		
