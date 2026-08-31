extends Node

## Añade soporte de mando (joypad) al Jugador 1, sin quitar el teclado.
## XInput/Xbox: cruceta + stick izquierdo para moverse; botones de cara + bumpers para
## los 6 ataques. Layout de pelea: puños = X/Y/RB, patadas = A/B/LB.

func _ready() -> void:
	# P1: any joypad (device -1) - covers 8BitDo BLE Switch/X/DInput
	for dev in [-1, 0, 1]:
		_add_dir_dev("p1_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0, dev)
		_add_dir_dev("p1_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0, dev)
		_add_dir_dev("p1_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0, dev)
		_add_dir_dev("p1_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0, dev)
		# face buttons: map both Xbox and Switch layouts (Switch swaps A/B and X/Y)
		_add_button_dev("p1_lp", JOY_BUTTON_X, dev); _add_button_dev("p1_lp", JOY_BUTTON_Y, dev)
		_add_button_dev("p1_mp", JOY_BUTTON_Y, dev); _add_button_dev("p1_mp", JOY_BUTTON_X, dev)
		_add_button_dev("p1_hp", JOY_BUTTON_RIGHT_SHOULDER, dev)
		_add_button_dev("p1_lk", JOY_BUTTON_A, dev); _add_button_dev("p1_lk", JOY_BUTTON_B, dev)
		_add_button_dev("p1_mk", JOY_BUTTON_B, dev); _add_button_dev("p1_mk", JOY_BUTTON_A, dev)
		_add_button_dev("p1_hk", JOY_BUTTON_LEFT_SHOULDER, dev)
		# P2 second pad same but also on any device for single-pad testing
		_add_dir_dev("p2_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0, dev)
		_add_dir_dev("p2_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0, dev)
		_add_dir_dev("p2_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0, dev)
		_add_dir_dev("p2_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0, dev)
		_add_button_dev("p2_lp", JOY_BUTTON_X, dev)
		_add_button_dev("p2_mp", JOY_BUTTON_Y, dev)
		_add_button_dev("p2_hp", JOY_BUTTON_RIGHT_SHOULDER, dev)
		_add_button_dev("p2_lk", JOY_BUTTON_A, dev)
		_add_button_dev("p2_mk", JOY_BUTTON_B, dev)
		_add_button_dev("p2_hk", JOY_BUTTON_LEFT_SHOULDER, dev)
	_add_button_dev("ui_accept", JOY_BUTTON_A, -1); _add_button_dev("ui_accept", JOY_BUTTON_B, -1)
	_add_button_dev("ui_cancel", JOY_BUTTON_B, -1); _add_button_dev("ui_cancel", JOY_BUTTON_A, -1)

func _add_button_dev(action: String, button: int, dev: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = dev
	InputMap.action_add_event(action, ev)

func _add_dir_dev(action: String, button: int, axis: int, value: float, dev: int) -> void:
	_add_button_dev(action, button, dev)
	var m := InputEventJoypadMotion.new()
	m.axis = axis
	m.axis_value = value
	m.device = dev
	InputMap.action_add_event(action, m)

# legacy aliases
func _add_button(action: String, button: int) -> void: _add_button_dev(action, button, -1)
func _add_dir(action: String, button: int, axis: int, value: float) -> void: _add_dir_dev(action, button, axis, value, -1)
func _add_button_p2(action: String, button: int) -> void: _add_button_dev(action, button, -1)
func _add_dir_p2(action: String, button: int, axis: int, value: float) -> void: _add_dir_dev(action, button, axis, value, -1)
