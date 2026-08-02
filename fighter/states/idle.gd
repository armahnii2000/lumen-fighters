extends State

## Reposo de pie. Reparte hacia los demás estados según el input.

func enter() -> void:
	fighter.stop_horizontal()

func physics_update(_delta: float) -> void:
	if fighter.try_start_special():
		state_machine.transition_to("Attack")
		return
	if fighter.try_start_attack("st"):
		state_machine.transition_to("Attack")
		return
	var dash: int = fighter.consume_dash()
	if dash != 0:
		fighter.begin_dash(dash)
		state_machine.transition_to("Dash")
		return
	if fighter.input.down:
		state_machine.transition_to("Crouch")
		return
	if fighter.input.up:
		state_machine.transition_to("JumpStartup")
		return
	if fighter.input.horizontal() != 0:
		state_machine.transition_to("Walk")
