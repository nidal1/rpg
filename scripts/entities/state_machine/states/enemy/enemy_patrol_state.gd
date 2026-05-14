# enemy_patrol_state.gd
extends State
class_name EnemyPatrolState

func enter() -> void:
	actor._stop_wandering()
	# Start with idle animation, _patrol will switch to run if moving
	if actor.animation_playback:
		actor.animation_playback.travel("run")
	
	actor._patrol()

func physics_update(_delta: float) -> void:
	if is_instance_valid(actor.target):
		transitioned.emit("enemychasestate")
		return
	
	actor._patrol()
	
	# If back at spawn position, go to idle
	if actor.global_position.distance_to(actor.spawn_position) < 5:
		transitioned.emit("enemyidlestate")
