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
	
	if actor.attack_type == Player.AttackType.BASIC_ATTACK:
		actor._on_attack_pressed()
	elif actor.attack_type == Player.AttackType.SKILL_ATTACK:
		GameManager.cast_attack_skill()
		actor._casting_skill()

func handle_input(event: InputEvent) -> void:
	# ONLY THE WARRIOR ACTOR CAN GO TO SECOND COMBO
	if (actor is Warrior or actor is Tank) and event.is_action_pressed("attack") and event.pressed:
		actor.attack_type = Player.AttackType.BASIC_ATTACK
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
	actor.attack_type = Player.AttackType.NONE
	actor.attack_skill = null
	transitioned.emit("playeridlestate")
