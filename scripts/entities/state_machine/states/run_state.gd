# run_state.gd
extends State
class_name RunState

func physics_update(_delta: float) -> void:
	if actor.direction == Vector2.ZERO:
		transitioned.emit("idlestate")
		return
	
	actor._move()
