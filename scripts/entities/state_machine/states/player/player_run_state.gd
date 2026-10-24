
extends State
class_name PlayerRunState


func _physics_process(_delta: float) -> void:

	# Keyboard movement has priority
	if actor.direction != Vector2.ZERO:

		if actor.has_mouse_target:
			actor.clear_target_position()

		actor._move()
		actor._move_and_slide()
		return

	# Mouse movement
	if actor.has_mouse_target:

		if actor.nav_agent.is_navigation_finished():
			actor.clear_target_position()
			actor.velocity = Vector2.ZERO

			transitioned.emit("playeridlestate")
			return

		actor._move_to_position()
		actor._move_and_slide()
		return

	# No movement
	actor.velocity = Vector2.ZERO
	actor._move_and_slide()

	transitioned.emit("playeridlestate")
