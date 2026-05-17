# enemy_chase_state.gd
extends State
class_name EnemyChaseState

const MAX_DISTANCE_TO_SPAWN_LOCATION: float = 700.0

func enter() -> void:
	actor._stop_wandering()

func physics_update(_delta: float) -> void:
	if not is_instance_valid(actor.target):
		transitioned.emit("enemypatrolstate")
		return
	
	actor._chase_target()

	var dist_to_spawn_location = actor.global_position.distance_to(actor.spawn_position)
	if dist_to_spawn_location > MAX_DISTANCE_TO_SPAWN_LOCATION:
		actor.set_target(null)
		transitioned.emit("enemypatrolstate")
		return

	if actor._target_reached():
		transitioned.emit("enemyattackstate")
