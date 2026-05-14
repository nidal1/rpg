# player_dead_state.gd
extends State
class_name PlayerDeadState

func enter() -> void:
	actor.velocity = Vector2.ZERO
	actor._die()

func physics_update(_delta: float) -> void:
	actor.velocity = Vector2.ZERO
