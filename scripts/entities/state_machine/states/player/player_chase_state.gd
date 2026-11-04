extends State
class_name PlayerChaseState


func _physics_process(_delta: float) -> void:
	actor.direction.x = Input.get_axis("move_left", "move_right")
	actor.direction.y = Input.get_axis("move_up", "move_down")

	if actor.direction != Vector2.ZERO or actor.is_targeting_position():
		if actor.state_machine.current_state is PlayerChaseState:
			transitioned.emit("playerrunstate")
			return
	
	actor._chase_target()
	if actor.target_reached():
		transitioned.emit("playerattackstate")
