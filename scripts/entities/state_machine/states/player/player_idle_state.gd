## PlayerIdleState
## State representing the player standing still.
extends State
class_name PlayerIdleState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	actor._idle()

func handle_input(event: InputEvent) -> void:
	# TODO: The transition to the attack state must have :
		# an enemy selected 
		# enemy in the attack range
	if event.is_action_pressed("attack") and event.pressed:
		transitioned.emit("playerattackstate")

func _physics_process(_delta: float) -> void:
	actor.direction.x = Input.get_axis("move_left", "move_right")
	actor.direction.y = Input.get_axis("move_up", "move_down")
	if actor.direction != Vector2.ZERO or actor.has_mouse_target:
		if actor.state_machine.current_state is PlayerIdleState:
			transitioned.emit("playerrunstate")
