# enemy_run_state.gd
extends State
class_name EnemyRunState

func enter() -> void:
	actor._stop_wandering()

func physics_update(_delta: float) -> void:
	if actor.direction == Vector2.ZERO:
		transitioned.emit("enemyidlestate")
		return
	
	actor._move()
