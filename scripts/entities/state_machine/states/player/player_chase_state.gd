extends State
class_name PlayerChaseState

func enter() -> void:
	print("entering to the chase state")

func physics_update(_delta: float) -> void:
	actor._chase_target()

	if actor.target_reached():
		transitioned.emit("playerattackstate")
