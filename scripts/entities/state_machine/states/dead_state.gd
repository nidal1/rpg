# dead_state.gd
extends State
class_name DeadState

func enter() -> void:
	print(actor.name, " has died.")
	
	actor.velocity = Vector2.ZERO
	
	# Handle specific death logic via virtual function
	actor._die()

func physics_update(_delta: float) -> void:
	# Ensure the character doesn't move or do anything while dead
	actor.velocity = Vector2.ZERO
