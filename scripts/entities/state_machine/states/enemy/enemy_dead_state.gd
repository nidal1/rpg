# enemy_dead_state.gd
extends State
class_name EnemyDeadState

func enter() -> void:
	actor.velocity = Vector2.ZERO
	
	# Handle specific death logic via virtual function
	actor._die()
	actor.on_died.emit()

func physics_update(_delta: float) -> void:
	# Ensure the enemy doesn't move while dead
	actor.velocity = Vector2.ZERO
