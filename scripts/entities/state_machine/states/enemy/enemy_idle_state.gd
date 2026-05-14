# enemy_idle_state.gd
extends State
class_name EnemyIdleState

func enter() -> void:
	actor._idle()
	actor.wander_cd.start()

func physics_update(_delta: float) -> void:
	if actor.direction != Vector2.ZERO:
		transitioned.emit("enemyrunstate")

	if actor.target and is_instance_valid(actor.target):
		if actor._target_reached():
			transitioned.emit("enemyattackstate")
		else:
			transitioned.emit("enemychasestate")
