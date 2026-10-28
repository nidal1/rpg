## Player
## Controls the player character, handling input, movement, combo attacks,
## and interactions with items and the environment.
extends Combatant
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
var attack_range: float = 300
var target: Enemy = null
var mouse_target_position: Vector2
var has_mouse_target: bool = false


# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var combo_timer: Timer = $ComboAttackCD
@onready var attack_state: PlayerAttackState = $StateMachine/PlayerAttackState

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()

	animation_tree = $AnimationTree
	animation_playback = animation_tree["parameters/playback"]
	animation_BA_playback = animation_tree["parameters/basic_attack/BasicAttackStateMachine/playback"]
	animation_tree.set_active(true)





# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func _move() -> void:
	velocity = direction.normalized() * speed
	if velocity.x != 0:
		last_facing_dir = sign(velocity.x)
		if animation_playback and animation_tree and animation_tree.is_active():
			animation_playback.travel("run")
			_play_movement_animation()

func _move_and_slide():
	move_and_slide()

## Moves the enemy toward a specific target position using the NavigationAgent.
func _move_to_position() -> void:
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	if global_position.distance_to(nav_agent.target_position) < 5:
		clear_target_position()
		return
	_move()

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

# ─── Public Methods ──────────────────────────────────────────────────────────
## Applies damage to the character.
func take_damage(amount: float) -> void:
	var reduced_damage = max(1.0, amount - _get_defense())
	var current_hp = StatsData.get_stats().get_current_hp()
	StatsData.get_stats().set_current_hp(max(0.0, current_hp - reduced_damage))
	_on_damage_received()

func set_target(_target: Enemy):
	target = _target

func get_target():
	return target

func set_target_position(_position: Vector2) -> void:
	mouse_target_position = _position
	has_mouse_target = true
	nav_agent.target_position = _position

func _get_target_position():
	return mouse_target_position

func clear_target_position() -> void:
	has_mouse_target = false
	EventBus.clear_selection_boxes.emit()

func _on_damage_received() -> void:
	var current_hp = StatsData.get_stats().get_current_hp()
	var max_hp = StatsData.get_stats().get_max_hp()
	EventBus.hero_hp_changed.emit(current_hp if current_hp > 0.0 else 0.0, max_hp)
	_flash_hit()
	if current_hp <= 0:
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
			return base_damage + character_class.get_class_stats().get_melee_atk()
		CharacterClass.PlayerType.ARCHER:
			return base_damage + character_class.get_class_stats().get_ranged_atk()
		CharacterClass.PlayerType.MAGE, CharacterClass.PlayerType.PRIEST:
			return base_damage + character_class.get_class_stats().get_magic_atk()
		_: return base_damage

# ─── Private Methods ─────────────────────────────────────────────────────────
## Initializes the player's stats based on the selected class.
func _load_classe(cls: CharacterClass) -> void:
	speed = cls.speed # Inherited from Character base class
	combo_chain = cls.combo_chain.duplicate(true)
	character_class.base_stats = character_class.get_class_stats()
	GameManager.register_player(self)

## Triggers the attack animation.
func _play_attack_animation(attack: AttackData) -> void:
	if animation_tree and animation_BA_playback:
		animation_BA_playback.travel(attack.anim_name)
		animation_tree.set(
			"parameters/basic_attack/BasicAttackStateMachine/%s/blend_position" % attack.anim_name,
			last_facing_dir
		)
		# if last_facing_dir <= 0:
		# 	animation_player.play("attack1_left")
		# else:
		# 	animation_player.play("attack1_right")

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
	if not is_instance_valid(self): return
	modulate = Color.WHITE

func _get_defense() -> float:
	return StatsData.get_stats().get_def()


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
			var item: DataItem = area.item
			EventBus.lootable_item_added.emit(item)

func _on_pickable_dection_area_exited(area: Area2D) -> void:
	if area.is_in_group("pickable"):
		if area is DropItem:
			var item: DataItem = area.item
			EventBus.lootable_item_removed.emit(item)
