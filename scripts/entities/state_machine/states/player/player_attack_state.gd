## PlayerAttackState
## State representing the player performing an attack or combo.
extends State
class_name PlayerAttackState

# ─── Signals ─────────────────────────────────────────────────────────────────
signal attack_ended

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	if not attack_ended.is_connected(_on_attack_end):
		attack_ended.connect(_on_attack_end)
	actor._on_attack_pressed()

func handle_input(event: InputEvent) -> void:
	# ONLY THE WARRIOR ACTOR CAN GO TO SECOND COMBO
	if actor is Warrior and event.is_action_pressed("attack") and event.pressed:
		actor._on_attack_pressed()

func physics_update(_delta: float) -> void:
	actor.velocity = Vector2.ZERO

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_attack_end() -> void:
	transitioned.emit("playeridlestate")
