# chase_state.gd
extends State
class_name ChaseState

func physics_update(_delta: float) -> void:
	if not is_instance_valid(actor.target):
		transitioned.emit("patrolstate")
		return

	var dist = actor.global_position.distance_to(actor.target.global_position)
	actor.is_target_reached = dist <= actor.attack_range
	
	if actor.is_target_reached:
		transitioned.emit("attackstate")
		return

	actor._chase_target()
