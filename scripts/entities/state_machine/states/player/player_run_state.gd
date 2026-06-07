## PlayerRunState
## State representing the player moving around.
extends State
class_name PlayerRunState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func physics_update(_delta: float) -> void:
	if actor.direction == Vector2.ZERO:
		transitioned.emit("playeridlestate")
		return
	
	actor._move()
