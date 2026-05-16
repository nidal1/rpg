extends Character
class_name Player

@export var speed: float = 300.0
@export var character_class: CharacterClass

@onready var combo_timer: Timer = $ComboAttackCD
@onready var attack_state: PlayerAttackState = $StateMachine/PlayerAttackState

var combo_index: int = -1
var combo_queued: bool = false
var combo_chain: Array[AttackData] = []

# ─── Virtual functions ────────────────────────────────────────────
func _play_attack_animation(attack: AttackData) -> void: pass

func _load_classe(cls: CharacterClass) -> void:
	max_health = cls.max_health
	speed = cls.speed
	combo_chain = cls.combo_chain.duplicate(true)

# ─── Input ───────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if state_machine:
			state_machine.transition_to("playerattackstate")

# ─── Physics ─────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	move_and_slide()

# ─── Combo ───────────────────────────────────────────────
func _on_attack_pressed() -> void: if combo_chain.size() > 0: _attack()

func _attack() -> void:
	if combo_index >= 0:
		if combo_index < combo_chain.size() - 1:
			combo_queued = true
		return
	_start_combo()

func _move() -> void:
	velocity = direction.normalized() * speed
	if velocity.x != 0:
		last_facing_dir = sign(velocity.x)
		if animation_playback and animation_tree and animation_tree.is_active():
			animation_playback.travel("run")
			_play_movement_animation()

func _idle() -> void:
	velocity = Vector2.ZERO
	if animation_playback and animation_tree and animation_tree.is_active():
		animation_playback.travel("idle")
		_play_idle_animation()

func _start_combo() -> void:
	combo_index = 0
	combo_queued = false
	_execute_attack()

func _execute_attack() -> void:
	if combo_index < 0 or combo_index >= combo_chain.size(): return
	var attack: AttackData = combo_chain[combo_index]
	if animation_playback and animation_tree and animation_tree.is_active():
		animation_playback.travel("basic_attack")
		_play_attack_animation(attack)
	combo_timer.wait_time = attack.combo_window
	combo_timer.start()

func _get_attack_damage() -> float:
	if combo_chain.size() == 1: return combo_chain[0].damage
	if combo_index < 0 or combo_index >= combo_chain.size(): return 0.0
	return combo_chain[combo_index].damage

func _end_combo() -> void:
	combo_index = -1
	combo_queued = false
	if attack_state:
		attack_state.attack_ended.emit()

func _on_combo_attack_cd_timeout() -> void:
	if combo_queued and combo_index < combo_chain.size() - 1:
		combo_index += 1
		combo_queued = false
		_execute_attack()
	else:
		_end_combo()

func _on_damage_received() -> void:
	print("Player hit! health remaining: ", max_health)
	_flash_hit()
	if max_health <= 0:
		state_machine.transition_to("playerdeadstate")

func _flash_hit() -> void:
	modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self ): return
	modulate = Color.WHITE

func _die() -> void:
	queue_free()
