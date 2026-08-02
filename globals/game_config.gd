extends Node

## Config global entre escenas (autoload). El menú la escribe; el MatchManager la lee.

var p2_is_cpu: bool = false
var cpu_difficulty: String = "medium"
var show_boxes: bool = true   # cajas de golpe/daño visibles (F1 para alternar)

func set_mode(cpu: bool, difficulty: String) -> void:
	p2_is_cpu = cpu
	cpu_difficulty = difficulty
