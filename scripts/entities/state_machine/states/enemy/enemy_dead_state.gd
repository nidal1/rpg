# enemy_dead_state.gd
extends State
class_name EnemyDeadState

func enter() -> void:
	actor.velocity = Vector2.ZERO
	actor._die()
	EventBus.enemy_died.emit(actor)
	
func physics_update(_delta: float) -> void:
	# Ensure the enemy doesn't move while dead
	actor.velocity = Vector2.ZERO
