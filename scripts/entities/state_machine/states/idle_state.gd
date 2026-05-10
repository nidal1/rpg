# idle_state.gd
extends State
class_name IdleState

func enter() -> void:
	actor._idle()

func physics_update(_delta: float) -> void:
	if actor.direction != Vector2.ZERO:
		transitioned.emit("runstate")
