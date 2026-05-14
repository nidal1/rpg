# enemy_chase_state.gd
extends State
class_name EnemyChaseState

func enter() -> void:
	actor._stop_wandering()

func physics_update(_delta: float) -> void:
	if not is_instance_valid(actor.target):
		transitioned.emit("enemypatrolstate")
		return
	
	actor._chase_target()
	
	if actor._target_reached():
		transitioned.emit("enemyattackstate")
