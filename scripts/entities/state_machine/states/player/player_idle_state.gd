## PlayerIdleState
## State representing the player standing still.
extends State
class_name PlayerIdleState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	actor._idle()

func physics_update(_delta: float) -> void:
	if actor.direction != Vector2.ZERO:
		transitioned.emit("playerrunstate")
