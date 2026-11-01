## PlayerIdleState
## State representing the player standing still.
extends State
class_name PlayerIdleState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	actor._idle()

func push_actor_to_attack(_enemy_to_attack: Enemy):
	var dist_to_enemy = actor.global_position.distance_to(_enemy_to_attack.global_position)
	
	var can_attack: bool = dist_to_enemy <= actor.attack_range

	if can_attack: transitioned.emit("playerattackstate")
	else: transitioned.emit("playerchasestate")

func handle_input(event: InputEvent) -> void:
	# TODO: The transition to the attack state must have :
		# an enemy selected 
		# enemy in the attack range
	
	if event.is_action_pressed("attack") and event.pressed:
		if GameManager.get_is_enemy_selected():

			push_actor_to_attack(GameManager.get_selected_enemy())
		
		else:
			var enemies_in_range: Array[Enemy] = actor.enemies_in_range
			if enemies_in_range.size():
				var selected_enemy: Enemy = enemies_in_range[0]
				if actor.enemies_in_range.has(selected_enemy):
					EventBus.select_enemy.emit(selected_enemy)
					push_actor_to_attack(selected_enemy)

		return

func _physics_process(_delta: float) -> void:
	actor.direction.x = Input.get_axis("move_left", "move_right")
	actor.direction.y = Input.get_axis("move_up", "move_down")
	if actor.direction != Vector2.ZERO or actor.has_mouse_target:
		if actor.state_machine.current_state is PlayerIdleState:
			transitioned.emit("playerrunstate")
