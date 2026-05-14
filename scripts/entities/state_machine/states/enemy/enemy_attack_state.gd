# enemy_attack_state.gd
extends State
class_name EnemyAttackState

func enter() -> void:
	actor._stop_wandering()

func _enemy_attack_logic() -> void:
	# Keep velocity zero during attack
	actor.velocity = Vector2.ZERO
	
	if actor.can_attack:
		# await is CRITICAL here to prevent the infinite loop with IdleState
		await actor._attack()
	else:
		# If we can't attack yet, stay in this state for a short time 
		# or wait for the next physics frame before transitioning
		await get_tree().process_frame
	
	if not is_instance_valid(actor): return
	
	if actor.target and is_instance_valid(actor.target):
		if actor._target_reached():
			# Transition back to idle to re-evaluate (cooldown handled by await above)
			transitioned.emit("enemyidlestate")
		else:
			transitioned.emit("enemychasestate")
	else:
		transitioned.emit("enemyidlestate")

func physics_update(_delta: float) -> void:
	# Velocity should be zero during attack
	actor.velocity = Vector2.ZERO
	_enemy_attack_logic()
