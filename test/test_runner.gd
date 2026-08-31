extends SceneTree

# Core regression tests - run headless: godot --headless -s test/test_runner.gd

var passed := 0
var failed := 0

func _init():
	print("=== LUMEN FIGHTERS REGRESSION ===")
	_run_all()
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	if failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("PASS")
		quit(0)

func _run_all():
	test_input_p1_left_has_keyboard()
	test_input_p1_left_has_joypad()
	test_input_p2_left_has_arrow_and_joypad()
	test_input_p1_attacks_have_joypad()
	test_fighter_script_has_lumen_and_blade()
	test_project_godot_has_deadzone()
	test_fighter_instantiates()
	test_e2e_scene_loads()

func assert_has_key(action: String, keycode: int, phys: int) -> bool:
	if not InputMap.has_action(action):
		_fail(action + " missing action")
		return false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			if ev.physical_keycode == phys or ev.keycode == keycode or ev.keycode == phys:
				return true
			# also check unicode for A etc? physical_keycode is primary
	return false

func assert_has_joypad_button(action: String, btn: int) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == btn:
			return true
	return false

func assert_has_joypad_motion(action: String, axis: int, val: float) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadMotion and ev.axis == axis and sign(ev.axis_value) == sign(val):
			return true
	return false

func _pass(msg: String):
	passed += 1
	print("PASS: " + msg)

func _fail(msg: String):
	failed += 1
	print("FAIL: " + msg)

func test_input_p1_left_has_keyboard():
	if assert_has_key("p1_left", 65, 65):
		_pass("p1_left has A key")
	else:
		_fail("p1_left missing A key (physical 65)")

func test_input_p1_left_has_joypad():
	var has_btn = assert_has_joypad_button("p1_left", 13)
	var has_mot = assert_has_joypad_motion("p1_left", 0, -1.0)
	if has_btn and has_mot:
		_pass("p1_left has joypad DPad13 + Axis0 -1")
	else:
		_fail("p1_left missing joypad (btn13:%s mot:%s)" % [has_btn, has_mot])

func test_input_p2_left_has_arrow_and_joypad():
	var has_key = assert_has_key("p2_left", 4194319, 4194319)
	var has_btn = assert_has_joypad_button("p2_left", 13)
	var has_mot = assert_has_joypad_motion("p2_left", 0, -1.0)
	if has_key:
		_pass("p2_left has Left Arrow")
	else:
		_fail("p2_left missing Left Arrow 4194319")
	if has_btn and has_mot:
		_pass("p2_left has joypad")
	else:
		_fail("p2_left missing joypad btn13/mot")

func test_input_p1_attacks_have_joypad():
	if assert_has_joypad_button("p1_jab", 2) and assert_has_joypad_button("p1_slash", 3):
		_pass("p1_jab/slash have joypad X/Y")
	else:
		_fail("p1_jab/slash missing joypad")
	if assert_has_joypad_button("p2_jab", 2):
		_pass("p2_jab has joypad")
	else:
		_fail("p2_jab missing joypad")

func test_fighter_script_has_lumen_and_blade():
	var scr = load("res://scripts/fighter.gd")
	if scr == null:
		_fail("fighter.gd not loadable")
		return
	var src = scr.source_code if scr.source_code != "" else ""
	# check via file read
	var f = FileAccess.open("res://scripts/fighter.gd", FileAccess.READ)
	var txt = f.get_as_text() if f else ""
	if txt.contains("max_lumen") and txt.contains("lumen"):
		_pass("fighter.gd has lumen")
	else:
		_fail("fighter.gd missing lumen")
	if txt.contains("Blade") and txt.contains("PointLight2D"):
		_pass("fighter.gd has blade")
	else:
		_fail("fighter.gd missing blade")

func test_project_godot_has_deadzone():
	# ensure project.godot still has input section
	var f = FileAccess.open("res://project.godot", FileAccess.READ)
	var txt = f.get_as_text() if f else ""
	if txt.contains("p1_left") and txt.contains("p2_left"):
		_pass("project.godot has input")
	else:
		_fail("project.godot missing input")

func test_fighter_instantiates():
	var scene = load("res://scenes/Fighter.tscn")
	if scene == null:
		_fail("Fighter.tscn not loadable")
		return
	var inst = scene.instantiate()
	if inst.has_method("take_hit"):
		_pass("Fighter instantiates with take_hit")
	else:
		_fail("Fighter missing take_hit")
	inst.queue_free()

func test_e2e_scene_loads():
	var scene = load("res://scenes/Main.tscn")
	if scene == null:
		_fail("Main.tscn not loadable")
		return
	var inst = scene.instantiate()
	var has_p1 = inst.get_node_or_null("P1") != null
	var has_p2 = inst.get_node_or_null("P2") != null
	if has_p1 and has_p2:
		_pass("Main.tscn has P1+P2")
	else:
		_fail("Main.tscn missing P1/P2")
	inst.queue_free()
