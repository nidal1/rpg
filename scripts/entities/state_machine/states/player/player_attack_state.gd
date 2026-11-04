## PlayerAttackState
## State representing the player performing an attack or combo.
extends State
class_name PlayerAttackState

# ─── Signals ─────────────────────────────────────────────────────────────────
signal attack_ended

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	# Validate target is still alive before attacking
	if actor.is_targeting_enemy():
		var target = actor.get_enemy_target()
		if not target or not is_instance_valid(target):
			# Enemy died or was freed, return to idle
			actor.clear_target()
			transitioned.emit("playeridlestate")
			return

	if not attack_ended.is_connected(_on_attack_end):
		attack_ended.connect(_on_attack_end)
	actor._on_attack_pressed()

func handle_input(event: InputEvent) -> void:
	# ONLY THE WARRIOR ACTOR CAN GO TO SECOND COMBO
	if actor is Warrior and event.is_action_pressed("attack") and event.pressed:
		actor._on_attack_pressed()

func physics_update(_delta: float) -> void:
	# Continuously validate target during attack
	if actor.is_targeting_enemy():
		var target = actor.get_enemy_target()
		if not target or not is_instance_valid(target):
			# Enemy died during attack, end attack early
			actor.clear_target()
			transitioned.emit("playeridlestate")
			return

	actor.velocity = Vector2.ZERO

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_attack_end() -> void:
	transitioned.emit("playeridlestate")
