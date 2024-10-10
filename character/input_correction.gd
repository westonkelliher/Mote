extends Node
class_name InputHandler

const SMALL := 0.0001

class GamepadInput:
	var stick_L := Vector2(0.0, 0.0)
	var stick_R := Vector2(0.0, 0.0)
	var trig_L := 0.0
	var trig_R := 0.0
	
	func rotated(a: float) -> GamepadInput:
		var gpi := GamepadInput.new()
		gpi.trig_L = trig_L
		gpi.trig_R = trig_R
		gpi.stick_L = stick_L.rotated(a)
		gpi.stick_R = stick_R.rotated(a)
		return gpi
	
	func is_nothing() -> bool:
		var no_stick := stick_L.length() < SMALL and stick_R.length() < SMALL
		var no_trig := trig_L < SMALL and trig_R < SMALL
		return no_stick and no_trig


#TODO: detect windows vs linux and ajust input mapping accordingly

# Called every frame. 'delta' is the elapsed time since the previous frame.
static func get_gamepad_input() -> GamepadInput:
	var gpi := GamepadInput.new()
	if !InputMap.has_action("LS_down"):
		return gpi # workaround for @tool being broken on inputs
	#
	var L_l := Input.get_action_raw_strength("LS_left")
	var L_r := Input.get_action_raw_strength("LS_right")
	var L_u := Input.get_action_raw_strength("LS_up")
	var L_d := Input.get_action_raw_strength("LS_down")
	var L_t0 := Input.get_action_raw_strength("LT0")
	var L_t1 := Input.get_action_raw_strength("LT1")
	#
	var R_l := Input.get_action_raw_strength("RS_left")
	var R_r := Input.get_action_raw_strength("RS_right")
	var R_u := Input.get_action_raw_strength("RS_up")
	var R_d := Input.get_action_raw_strength("RS_down")
	var R_t0 := Input.get_action_raw_strength("RT0")
	var R_t1 := Input.get_action_raw_strength("RT1")
	#
	var L_stick := correct_and_convert_stick(L_l, L_r, L_u, L_d)
	var L_trig := correct_and_convert_trigger(L_t0, L_t1)
	var R_stick := correct_and_convert_stick(R_l, R_r, R_u, R_d)
	var R_trig := correct_and_convert_trigger(R_t0, R_t1)
	#
	gpi.stick_L = L_stick
	gpi.stick_R = R_stick
	gpi.trig_L = L_trig
	gpi.trig_R = R_trig
	return gpi
	#
	#
	#$ForeArm.basis = $BaseArm/Arm.basis



static func correct_and_convert_stick(stick_l: float, stick_r: float, stick_u: float, stick_d: float) -> Vector2:
	var stick_totals := pow((0.01 + stick_l + stick_r + stick_u + stick_d), .9)
	var raw_x := stick_r - stick_l
	var raw_y := stick_u - stick_d
	var raw_diff: float = abs(abs(raw_x) - abs(raw_y))
	var final_x := raw_x / (1 + pow(1 - raw_diff, 1.5)*0.3)
	var final_y := raw_y / (1 + pow(1 - raw_diff, 1.5)*0.3)
	return Vector2(final_x, final_y)

static func correct_and_convert_trigger(lt0: float, lt1: float) -> float:
	var trig := (1.0 - lt0 + lt1)/2.0
	if lt0 == 0 && lt1 == 0:
		trig = 0
	return trig
