## PlayerDeadState
## State representing a dead player. Stops movement and handles death logic.
extends State
class_name PlayerDeadState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	actor.velocity = Vector2.ZERO
	actor._die()

func physics_update(_delta: float) -> void:
	actor.velocity = Vector2.ZERO
