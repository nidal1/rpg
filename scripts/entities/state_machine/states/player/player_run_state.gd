# player_run_state.gd
extends State
class_name PlayerRunState

func physics_update(_delta: float) -> void:
	if actor.direction == Vector2.ZERO:
		transitioned.emit("playeridlestate")
		return
	
	actor._move()
