extends State
class_name PlayerChaseState


func physics_update(_delta: float) -> void:
	actor._chase_target()
	if actor.target_reached():
		transitioned.emit("playerattackstate")
