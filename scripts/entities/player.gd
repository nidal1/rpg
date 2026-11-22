## Player
## Controls the player character, handling input, movement, combo attacks,
## and interactions with items and the environment.
extends Combatant
class_name Player

# ─── Enums ───────────────────────────────────────────────────────────────────
## Defines the type of target the player is currently pursuing.
enum TargetType {
	NONE,      ## No active target
	ENEMY,     ## Following/attacking an enemy
	POSITION   ## Moving to a ground position
}

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

## Current target type (NONE, ENEMY, or POSITION)
var target_type: TargetType = TargetType.NONE
## The enemy being targeted (only valid when target_type == ENEMY)
var target_enemy: Enemy = null
## The ground position being targeted (only valid when target_type == POSITION)
var target_position: Vector2 = Vector2.ZERO

var enemies_in_range: Array[Enemy] = []

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var combo_timer: Timer = $ComboAttackCD
@onready var attack_state: PlayerAttackState = $StateMachine/PlayerAttackState
@onready var detection_zone: Area2D = $DetectionZone
@onready var buffs_durations_container: Node = $BuffsDurationsContainer

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()

	animation_tree = $AnimationTree
	animation_playback = animation_tree["parameters/playback"]
	animation_BA_playback = animation_tree["parameters/basic_attack/BasicAttackStateMachine/playback"]
	player_animation_BA_attack_speed_parameter_path = "parameters/basic_attack/BasicAttackStateMachine/%s/attack_speed/scale"
	animation_tree.set_active(true)

	EventBus.stats_updated.connect(_on_stats_updated)
	EventBus.enemy_unselected.connect(_on_enemy_unselected)
	EventBus.buff_skill_duration_started.connect(_on_buff_skill_duration_started)

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

## Moves the player toward the current nav_agent target position.
func _move_to_position(max_distance: float = 5) -> void:
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	if global_position.distance_to(nav_agent.target_position) < max(5, max_distance):
		if target_type == TargetType.POSITION:
			clear_target()
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

## Chases the current enemy target.
func _chase_target() -> void:
	if not is_targeting_enemy():
		return

	# Update nav agent to track moving enemy
	nav_agent.target_position = target_enemy.global_position
	_move_to_position(attack_range)
	_move_and_slide()

## Moves toward a ground position target.
func _move_to_ground_target() -> void:
	if not is_targeting_position():
		return

	_move_to_position(5.0)  # Stop within 5 pixels
	_move_and_slide()


# ─── Public Methods ──────────────────────────────────────────────────────────
## Applies damage to the character.
func take_damage(hit_data: Dictionary) -> void:
	var _hit = hit_data.get("hit")
	var _is_crit = hit_data.get("is_crit")
	var _damage = hit_data.get("damage")

	if not _hit:
		print("The hit is evaded")
		return 

	var absorption = max(0.0, float(StatsData.get_absorption()))
	var absorbed_amount = max(0.0, _damage - absorption)

	if absorbed_amount <= 0.0:
		print("The damage is absorbed")
		return

	var reduced_damage = max(1.0, absorbed_amount - _get_physical_defense())
	var current_hp = StatsData.get_current_hp()
	StatsData.set_current_hp(max(0.0, current_hp - reduced_damage))
	_on_damage_received()

## Sets an enemy as the current target.
func set_enemy_target(enemy: Enemy) -> void:
	target_type = TargetType.ENEMY
	target_enemy = enemy
	target_position = Vector2.ZERO
	nav_agent.target_position = enemy.global_position

## Sets a ground position as the current target.
func set_ground_target(pos: Vector2) -> void:
	target_type = TargetType.POSITION
	target_enemy = null
	target_position = pos
	nav_agent.target_position = pos

## Clears all targeting state.
func clear_target() -> void:
	target_type = TargetType.NONE
	target_enemy = null
	target_position = Vector2.ZERO

## Returns true if the player has any active target.
func has_target() -> bool:
	return target_type != TargetType.NONE

## Returns true if currently targeting an enemy.
func is_targeting_enemy() -> bool:
	return target_type == TargetType.ENEMY and target_enemy != null and is_instance_valid(target_enemy)

## Returns true if currently targeting a ground position.
func is_targeting_position() -> bool:
	return target_type == TargetType.POSITION

## Gets the current target position (works for both enemy and ground targets).
func get_current_target_position() -> Vector2:
	match target_type:
		TargetType.ENEMY:
			return target_enemy.global_position if is_targeting_enemy() else Vector2.ZERO
		TargetType.POSITION:
			return target_position
		_:
			return Vector2.ZERO

## Checks if the current target has been reached.
func target_reached() -> bool:
	match target_type:
		TargetType.ENEMY:
			return is_targeting_enemy() and global_position.distance_to(target_enemy.global_position) <= attack_range
		TargetType.POSITION:
			return global_position.distance_to(target_position) <= 5.0
		_:
			return false

## Gets the current enemy target (null if not targeting an enemy).
func get_enemy_target() -> Enemy:
	return target_enemy if is_targeting_enemy() else null

func get_evasion() -> float:
	return StatsData.get_evasion()

func _on_damage_received() -> void:
	var current_hp = StatsData.get_current_hp()
	var max_hp = StatsData.get_max_hp()
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

func _get_attack_damage(defender_eva: float) -> Dictionary:
	if not StatsData.roll_hit(defender_eva):
		return {"hit": false, "is_crit": false, "damage": 0.0}

	var base_damage: float = 0.0
	# combine attack-specific damage with stat-based power
	match character_class.player_type:
		CharacterClass.PlayerType.WARRIOR:
			base_damage = StatsData.get_melee_atk()
		CharacterClass.PlayerType.ARCHER:
			base_damage = StatsData.get_ranged_atk()
		CharacterClass.PlayerType.MAGE, CharacterClass.PlayerType.PRIEST:
			base_damage = StatsData.get_magic_atk()
		_: base_damage = 0.0
	
	

	var is_crit: bool = (randf() * 100.0) < StatsData.get_crit_chance()
	var final_damage: float = base_damage * StatsData.get_crit_damage() if is_crit else base_damage

	return {"hit": true, "is_crit": is_crit, "damage": final_damage}

# ─── Private Methods ─────────────────────────────────────────────────────────
## Initializes the player's stats based on the selected class.
func _load_classe(cls: CharacterClass) -> void:
	# speed = cls.speed # Inherited from Character base class
	combo_chain = cls.combo_chain.duplicate(true)
	# attack_range = cls.attack_range
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
	var speed_scale := _get_attack_speed_scale()

	_set_attack_timescale(attack, speed_scale)

	if animation_playback and animation_tree and animation_tree.is_active():
		animation_playback.travel("basic_attack")
		_play_attack_animation(attack)
	combo_timer.wait_time = max(0.05, attack.combo_window / speed_scale)
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

func _get_physical_defense() -> float:
	return StatsData.get_physical_defense()

func _get_attack_speed_scale() -> float:
	return StatsData.get_attack_speed()

func _set_attack_timescale(attack: AttackData, speed_scale: float) -> void:
	if not animation_tree:
		return

	var scale_path := player_animation_BA_attack_speed_parameter_path % attack.anim_name
	if animation_tree.get(scale_path) != null:
		animation_tree.set(scale_path, speed_scale)

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

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if not body in enemies_in_range:
			enemies_in_range.append(body)

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if enemies_in_range.size() and body in enemies_in_range:
			enemies_in_range.erase(body)

func _on_enemy_unselected(_enemy: Enemy):
	clear_target()

func _on_stats_updated():
	var stats = StatsData.get_secondary_stats_breakdown()
	speed = stats.get("movement_speed", 0.0)
	attack_range = stats.get("attack_range", 0.0)
	detection_zone.get_node("CollisionShape2D").shape.radius = attack_range

func _on_buff_skill_duration_started(_skill: BuffSkill, _value: float):
	var _id = _skill.skill_id
	var _duration = _skill.duration

	var _buff_duration = BuffSkillDuration.new(_skill, _value)
	buffs_durations_container.add_child(_buff_duration)