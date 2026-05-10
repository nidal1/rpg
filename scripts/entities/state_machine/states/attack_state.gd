# attack_state.gd
extends State
class_name AttackState

signal attack_ended

func _on_attack_end() -> void:
	transitioned.emit("idlestate")

func enter() -> void:
	if actor is Player:
		if not attack_ended.is_connected(_on_attack_end):
			attack_ended.connect(_on_attack_end)
		actor._on_attack_pressed()
	elif actor is Enemy:
		_enemy_attack_logic()

func _enemy_attack_logic() -> void:
	# Keep velocity zero during attack
	actor.velocity = Vector2.ZERO
	
	if actor.can_attack:
		await actor._attack()
	
	if not is_instance_valid(actor): return
	
	if actor.target:
		actor.is_target_reached = (actor.global_position.distance_to(actor.target.global_position) <= actor.attack_range)
		if actor.is_target_reached:
			transitioned.emit("idlestate")
		else:
			transitioned.emit("chasestate")
	else:
		transitioned.emit("idlestate")

func handle_input(event: InputEvent) -> void:
	# Handle subsequent clicks for combos while already in attack state
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if actor is Player:
			actor._on_attack_pressed()

func physics_update(_delta: float) -> void:
	# Velocity should be zero during attack for most characters
	actor.velocity = Vector2.ZERO
