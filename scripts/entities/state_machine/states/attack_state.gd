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
	else:
		actor._attack()

func handle_input(event: InputEvent) -> void:
	# Handle subsequent clicks for combos while already in attack state
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if actor is Player:
			actor._on_attack_pressed()

func physics_update(_delta: float) -> void:
	# Velocity should be zero during attack for most characters
	actor.velocity = Vector2.ZERO
