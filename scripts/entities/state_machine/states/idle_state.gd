# idle_state.gd
extends State
class_name IdleState

func enter() -> void:
	actor._idle()
	if is_instance_valid(actor) and actor is Enemy and actor.target and is_instance_valid(actor.target):
		actor.is_target_reached = (actor.global_position.distance_to(actor.target.global_position) <= actor.attack_range)
		if actor.is_target_reached:
			transitioned.emit("attackstate")
		else:
			transitioned.emit("chasestate")

func physics_update(_delta: float) -> void:
	if actor.direction != Vector2.ZERO:
		transitioned.emit("runstate")
