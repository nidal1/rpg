# idle_state.gd
extends State
class_name IdleState

func enter() -> void:
	actor._idle()
	if is_instance_valid(actor) and actor is Enemy:
		if actor.target and is_instance_valid(actor.target):
			if actor._target_reached():
				transitioned.emit("attackstate")
			else:
				transitioned.emit("chasestate")
		else:
			actor.wander_cd.start()

func physics_update(_delta: float) -> void:
	if actor.direction != Vector2.ZERO:
		transitioned.emit("runstate")
