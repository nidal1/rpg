## Enemy
## Base class for enemies, managing AI navigation, wandering, attacks, and drops.
extends Combatant
class_name Enemy

# ─── Signals ─────────────────────────────────────────────────────────────────
## Emitted when the enemy spawns.
signal on_spawned(spawn_position: Vector2)
## Emitted when the enemy finishes wandering.
signal on_wander_finished

# ─── Exported Variables ──────────────────────────────────────────────────────
## The stats and parameters specific to this enemy.
@export var enemy_params: EnemyParams

# ─── Public Variables ────────────────────────────────────────────────────────
## The scene instantiated when the enemy drops an item.
var drop_item_scene: PackedScene = preload("res://scenes/entities/items/drop.tscn")

var is_target_reached: bool = false
var can_attack: bool = true
var target: CharacterBody2D = null

var attack_cooldown: float
var attack_range: float
var attack_damage: float
var enemy_name: String = ""
var enemy_level: int = 1
var enemy_rank: ProgressionManager.EnemyRank = ProgressionManager.EnemyRank.NORMAL
var base_attack_anim_duration: float = 1.0
var base_recovery_delay: float = 1.0
var wander_cd_time: float = 5.0
var is_wandering: bool = false
var spawn_position: Vector2

var max_health: float = 0.0
var current_health: float = 0.0

var current_timescale: float = 0.5

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var wander_cd: Timer = $WanderCD
@onready var enemy_avatar: TextureRect = $EnemyStats/EnemyAvatar
@onready var enemy_hp_progress_bar: TextureProgressBar = $EnemyStats/EnemyHPProgressBar
@onready var enemy_hp_points: Label = $EnemyStats/EnemyHPPoints

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	wander_cd.wait_time = wander_cd_time
	
	animation_tree = $AnimationTree
	animation_playback = animation_tree["parameters/playback"]
	animation_BA_attack_speed_parameter_path = "parameters/basic_attack/attack_speed/scale"
	animation_tree.set_active(true)


func _physics_process(_delta: float) -> void:
	move_and_slide()

# ─── Public Methods ──────────────────────────────────────────────────────────
## Applies damage to the character.
func take_damage(amount: float) -> void:
	var reduced_damage = max(1.0, amount - _get_defense())
	current_health -= reduced_damage
	_on_damage_received()

## Sets a new target for the enemy to chase.
func set_target(new_target: CharacterBody2D) -> void:
	target = new_target

## Returns the current target.
func get_target() -> CharacterBody2D:
	return target

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func _move() -> void:
	velocity = direction.normalized() * speed
	if velocity.x != 0:
		last_facing_dir = sign(velocity.x)
		if animation_playback and animation_tree and animation_tree.is_active():
			animation_playback.travel("run")
			_play_movement_animation()

func _idle() -> void:
	direction = Vector2.ZERO
	velocity = Vector2.ZERO
	if animation_playback and animation_tree and animation_tree.is_active():
		animation_playback.travel("idle")
		_play_idle_animation()

func _attack() -> void:
	can_attack = false
	animation_playback.travel("basic_attack")
	_play_attack_animation()

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self): return
	can_attack = true

func _die() -> void:
	queue_free()


func _on_damage_received() -> void:
	_set_hp_progress_bar_value(max(0.0, current_health))
	_flash_hit()
	if current_health <= 0:
		state_machine.transition_to("enemydeadstate")

func _get_attack_damage() -> float:
	return attack_damage

func _play_movement_animation() -> void:
	animation_tree.set("parameters/run/blend_position", last_facing_dir)

func _play_idle_animation() -> void:
	animation_tree.set("parameters/idle/blend_position", last_facing_dir)

func _play_attack_animation() -> void:
	animation_tree.set("parameters/basic_attack/BlendSpace1D/blend_position", last_facing_dir)

## Loads the enemy's stats and parameters.
func _load_params(params: EnemyParams) -> void:
	max_health = params.max_health
	current_health = max_health
	speed = params.speed
	attack_damage = params.attack_damage
	attack_range = params.attack_range
	base_recovery_delay = params.base_recovery_delay

	enemy_name = params.enemy_name
	enemy_level = params.enemy_level
	enemy_rank = params.enemy_rank
	base_attack_anim_duration = params.base_attack_anim_duration

	_apply_progression_scaling()
	_initialize_enemy_stats(max_health, params.enemy_avatar)

## Initializes the enemy's UI stats.
func _initialize_enemy_stats(_max_health: float, _avatar_texture: Texture2D) -> void:
	_set_hp_progress_bar_max_value(_max_health)
	_set_hp_progress_bar_value(_max_health)
	enemy_avatar.texture = _avatar_texture

## Sets the HP progress bar value.
func _set_hp_progress_bar_value(value: float) -> void:
	enemy_hp_progress_bar.value = max(0.0, min(value, max_health))
	enemy_hp_points.text = "%d / %d" % [value, max_health]

## Sets the maximum HP progress bar value.
func _set_hp_progress_bar_max_value(value: float) -> void:
	enemy_hp_progress_bar.max_value = value

## Moves the enemy toward a specific target position using the NavigationAgent.
func _move_to_position(_target_position: Vector2) -> void:
	nav_agent.target_position = _target_position
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	if global_position.distance_to(nav_agent.target_position) < 1:
		print("Target reached")
		return
	_move()

## Chases the current target.
func _chase_target() -> void:
	if not is_instance_valid(target): return
	nav_agent.target_position = target.global_position
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	_move()

## Patrols back to the spawn position.
func _patrol() -> void:
	_move_to_position(spawn_position)

## Checks if the target is within attack range.
func _target_reached() -> bool:
	return target and global_position.distance_to(target.global_position) < attack_range

## Returns the defense of the enemy.
func _get_defense() -> float: return enemy_params.defense

## Wanders to a specific position.
func _wander(_to_position: Vector2) -> void:
	if global_position.distance_to(_to_position) < 1:
		velocity = Vector2.ZERO
		on_wander_finished.emit()
	else:
		_move_to_position(_to_position)

## Stops the wander cooldown timer.
func _stop_wandering() -> void:
	wander_cd.stop()

## Instantiates and returns the items dropped by the enemy.
func _drop_item() -> Array[DropItem]:
	var drops: Array[DropItem] = []
	for item in enemy_params.custom_db_item_objects:
		var drop_item: DropItem = drop_item_scene.instantiate()
		drop_item.item = item
		drops.append(drop_item)
	return drops

func _apply_progression_scaling() -> void:
	# Calculate scaled damage
	attack_damage = ProgressionManager.get_enemy_damage(enemy_level, enemy_rank, enemy_params.attack_damage if enemy_params else 10.0)
	
	# Calculate scaled attack speed (capped at 1.0)
	current_timescale = ProgressionManager.get_enemy_attack_speed(enemy_level)
	# Update attack cooldown dynamically based on total attack cycle formula
	attack_cooldown = ProgressionManager.get_total_attack_cycle(base_attack_anim_duration, current_timescale, base_recovery_delay)
	
	# Update AnimationTree TimeScale parameter node
	ProgressionManager.update_animation_timescale(animation_tree, current_timescale, animation_BA_attack_speed_parameter_path)

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("player"):
		target_node.take_damage(_get_attack_damage())

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = null

func _on_wander_cd_timeout() -> void:
	state_machine.transition_to("enemywanderstate")
