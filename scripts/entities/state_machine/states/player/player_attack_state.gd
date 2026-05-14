# player_attack_state.gd
extends State
class_name PlayerAttackState

signal attack_ended

func _on_attack_end() -> void:
	transitioned.emit("playeridlestate")

func enter() -> void:
	if not attack_ended.is_connected(_on_attack_end):
		attack_ended.connect(_on_attack_end)
	actor._on_attack_pressed()

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		actor._on_attack_pressed()

func physics_update(_delta: float) -> void:
	actor.velocity = Vector2.ZERO
