## EnemyIdleState
## State representing an enemy standing still, potentially waiting to wander.
extends State
class_name EnemyIdleState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	actor._idle()
	actor.wander_cd.start()

func physics_update(_delta: float) -> void:
	if actor.is_out_of_spawn_zone:
		transitioned.emit("enemypatrolstate")
		return
	if actor.direction != Vector2.ZERO:
		transitioned.emit("enemyrunstate")
		return
	if actor.target and is_instance_valid(actor.target):
		if actor._target_reached():
			transitioned.emit("enemyattackstate")
		else:
			transitioned.emit("enemychasestate")
