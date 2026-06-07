## EnemyRunState
## State representing an enemy moving towards a target or path position.
extends State
class_name EnemyRunState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	actor._stop_wandering()

func physics_update(_delta: float) -> void:
	if actor.direction == Vector2.ZERO:
		transitioned.emit("enemyidlestate")
		return
	
	actor._move()
