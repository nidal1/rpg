## PlayerRunState
## State representing the player running/moving.
extends State
class_name PlayerRunState

func physics_update(_delta: float) -> void:
	# Keyboard movement has priority
	if actor.direction != Vector2.ZERO:
		EventBus.clear_selection_boxes.emit()
		# Clear any mouse/enemy target when using keyboard
		if actor.has_target():
			EventBus.unselect_enemy.emit()
			

		actor._move()
		actor._move_and_slide()
		return

	# Ground position movement
	if actor.is_targeting_position():
		if actor.target_reached() or actor.nav_agent.is_navigation_finished():
			EventBus.unselect_enemy.emit()
			actor.velocity = Vector2.ZERO
			transitioned.emit("playeridlestate")
			return

		actor._move_to_ground_target()
		return

	# No movement - return to idle
	if actor.state_machine.current_state is PlayerRunState:
		actor.velocity = Vector2.ZERO
		actor._move_and_slide()
		transitioned.emit("playeridlestate")
