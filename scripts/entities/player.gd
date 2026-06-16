## Player
## Controls the player character, handling input, movement, combo attacks,
## and interactions with items and the environment.
extends Character
class_name Player

# ─── Exported Variables ──────────────────────────────────────────────────────
## The class data defining the player's starting stats and abilities.
@export var character_class: CharacterClass

# ─── Public Variables ────────────────────────────────────────────────────────
## The current index in the combo chain.
var combo_index: int = -1
## Whether the next combo attack is queued.
var combo_queued: bool = false
## The list of attacks forming the combo chain.
var combo_chain: Array[AttackData] = []

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var combo_timer: Timer = $ComboAttackCD
@onready var attack_state: PlayerAttackState = $StateMachine/PlayerAttackState

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()

	animation_tree = $AnimationTree
	animation_playback = animation_tree["parameters/playback"]
	animation_BA_playback = animation_tree["parameters/basic_attack/BasicAttackStateMachine/playback"]
	animation_tree.set_active(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if state_machine:
			state_machine.transition_to("playerattackstate")

func _physics_process(_delta: float) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	move_and_slide()

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
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

func _attack() -> void:
	if combo_index >= 0:
		if combo_index < combo_chain.size() - 1:
			combo_queued = true
		return
	_start_combo()

func _die() -> void:
	queue_free()

func _on_damage_received() -> void:
	EventBus.update_hp_bar_value.emit(current_health if current_health > 0.0 else 0.0)
	_flash_hit()
	if current_health <= 0:
		state_machine.transition_to("playerdeadstate")

func _play_movement_animation() -> void:
	if animation_tree:
		animation_tree.set("parameters/run/blend_position", last_facing_dir)

func _play_idle_animation() -> void:
	if animation_tree:
		animation_tree.set("parameters/idle/blend_position", last_facing_dir)

func _get_attack_damage() -> float:
	var base_damage: float = 0.0
	if combo_chain.size() == 1:
		base_damage = combo_chain[0].damage
	elif combo_index >= 0 and combo_index < combo_chain.size():
		base_damage = combo_chain[combo_index].damage
	
	# combine attack-specific damage with stat-based power
	match character_class.player_type:
		CharacterClass.PlayerType.WARRIOR:
			return base_damage + PlayerData.get_melee_atk()
		CharacterClass.PlayerType.ARCHER:
			return base_damage + PlayerData.get_ranged_atk()
		CharacterClass.PlayerType.MAGE, CharacterClass.PlayerType.PRIEST:
			return base_damage + PlayerData.get_magic_atk()
		_: return base_damage

# ─── Private Methods ─────────────────────────────────────────────────────────
## Initializes the player's stats based on the selected class.
func _load_classe(cls: CharacterClass) -> void:
	max_health = cls.max_health
	current_health = max_health
	max_mana = cls.max_mana
	current_mana = max_mana
	speed = cls.speed # Inherited from Character base class
	combo_chain = cls.combo_chain.duplicate(true)

	GameManager.register_player(self )

## Triggers the attack animation.
func _play_attack_animation(attack: AttackData) -> void:
	if animation_tree and animation_BA_playback:
		animation_tree.set(
			"parameters/basic_attack/BasicAttackStateMachine/%s/blend_position" % attack.anim_name,
			last_facing_dir
		)
		animation_BA_playback.travel(attack.anim_name)

## Starts the attack combo chain.
func _start_combo() -> void:
	combo_index = 0
	combo_queued = false
	_execute_attack()

## Executes the current attack in the combo chain.
func _execute_attack() -> void:
	if combo_index < 0 or combo_index >= combo_chain.size(): return
	var attack: AttackData = combo_chain[combo_index]
	if animation_playback and animation_tree and animation_tree.is_active():
		animation_playback.travel("basic_attack")
		_play_attack_animation(attack)
	combo_timer.wait_time = attack.combo_window
	combo_timer.start()

## Ends the combo chain.
func _end_combo() -> void:
	if animation_BA_playback:
		animation_BA_playback.travel("End")
	combo_index = -1
	combo_queued = false
	if attack_state:
		attack_state.attack_ended.emit()

## Flashes the player red to indicate damage taken.
func _flash_hit() -> void:
	modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self ): return
	modulate = Color.WHITE

func _get_defense() -> float:
	return PlayerData.get_def()

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_attack_pressed() -> void:
	if combo_chain.size() > 0:
		_attack()

func _on_combo_attack_cd_timeout() -> void:
	if combo_queued and combo_index < combo_chain.size() - 1:
		combo_index += 1
		combo_queued = false
		_execute_attack()
	else:
		_end_combo()

func _on_pickable_dection_area_entered(area: Area2D) -> void:
	if area.is_in_group("pickable"):
		if area is DropItem:
			var item: Item = area.item
			EventBus.lootable_item_added.emit(item)

func _on_pickable_dection_area_exited(area: Area2D) -> void:
	if area.is_in_group("pickable"):
		if area is DropItem:
			var item: Item = area.item
			EventBus.lootable_item_removed.emit(item)
