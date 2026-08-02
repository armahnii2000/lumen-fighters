# Integración Fase 8 (cierre): menú principal + modo vs CPU.
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")
const MENU := preload("res://ui/main_menu.tscn")

func after_test() -> void:
	GameConfig.p2_is_cpu = false
	GameConfig.cpu_difficulty = "medium"

func test_menu_scene_has_mode_buttons() -> void:
	var menu := MENU.instantiate()
	add_child(menu)
	auto_free(menu)
	assert_object(menu.get_node("VBox/Btn2P")).is_not_null()
	assert_object(menu.get_node("VBox/BtnHard")).is_not_null()

func test_cpu_mode_makes_p2_ai() -> void:
	GameConfig.p2_is_cpu = true
	GameConfig.cpu_difficulty = "easy"
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	var p2: Fighter = m.get_node("Player2")
	assert_bool(p2.input_source is AIInput).is_true()

func test_2p_mode_keeps_p2_human() -> void:
	GameConfig.p2_is_cpu = false
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	var p2: Fighter = m.get_node("Player2")
	assert_bool(p2.input_source is HumanInput).is_true()
