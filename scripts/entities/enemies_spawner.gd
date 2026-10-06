## EnemiesSpawner
## Manages the periodic spawning of enemies within a specified radius
## using custom spawn configurations (EnemySpawnConfig) and handles item drop cleanups.
extends Node2D
class_name EnemiesSpawner

# ─── Exported Variables ──────────────────────────────────────────────────────
## The point around which enemies will be spawned.
@export var spawn_point: Marker2D
## An array of spawn configurations defining enemy scenes, quantities, and types.
@export var spawn_configs: Array[EnemySpawnConfig] = []
## The radius around the spawner where enemies can appear.
@export var spawn_circle_radius: float = 100.0
## Time in seconds before a defeated enemy respawns.
@export var respawn_cd: float = 60.0
## Time an enemy spends wandering before choosing a new action.
@export var wander_cd_time: float = 20.0

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var drop_zone: Node2D = %DropZone

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	_spawn_all_configured_enemies()
	EventBus.selected_lootable_items_picked_up.connect(remove_selected_drops)

# ─── Public Methods ──────────────────────────────────────────────────────────
## Calculates a random spawning location within the spawn circle radius around the spawn origin.
func randomize_spawning_location(spawn_position: Vector2) -> Vector2:
	return spawn_position + Vector2(
		randf_range(-spawn_circle_radius, spawn_circle_radius),
		randf_range(-spawn_circle_radius, spawn_circle_radius)
	)

## Returns the spawn origin vector, using spawn_point if assigned, or global_position as fallback.
func get_spawn_origin() -> Vector2:
	if is_instance_valid(spawn_point):
		return spawn_point.global_position
	return global_position

## Returns the node acting as the drop zone for items.
func get_drop_zone() -> Node:
	return drop_zone

## Removes an enemy reference and initiates the respawn timer.
func remove_enemy(_enemy: Enemy = null) -> void:
	await get_tree().create_timer(respawn_cd).timeout
	_spawn_random_configured_enemy()

## Removes the physical representations of items that the player picked up.
func remove_selected_drops(items: Array[DataItem]) -> void:
	if not is_instance_valid(drop_zone):
		return
	for drop in drop_zone.get_children():
		if drop.item in items:
			drop.queue_free()

# ─── Private Methods ─────────────────────────────────────────────────────────
## Iterates through spawn_configs and spawns the specified quantity for each valid and enabled config.
func _spawn_all_configured_enemies() -> void:
	for config in spawn_configs:
		if not _is_config_valid(config):
			continue
		for _i in range(config.quantity):
			_spawn_enemy_from_scene(config.scene)

## Respawns a random enemy from the enabled spawn configurations.
func _spawn_random_configured_enemy() -> void:
	var valid_scenes: Array[PackedScene] = []
	for config in spawn_configs:
		if _is_config_valid(config):
			valid_scenes.append(config.scene)
	
	if valid_scenes.is_empty():
		return
		
	var chosen_scene: PackedScene = valid_scenes[randi() % valid_scenes.size()]
	_spawn_enemy_from_scene(chosen_scene)

## Validates if a spawn configuration is non-null, enabled, and contains a scene.
func _is_config_valid(config: EnemySpawnConfig) -> bool:
	return config != null and config.enabled and config.scene != null

## Instantiates an enemy scene, positions it around spawn origin, and emits the spawn signal.
func _spawn_enemy_from_scene(enemy_scene: PackedScene) -> Enemy:
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	add_child(enemy)
	var origin: Vector2 = get_spawn_origin()
	var spawn_pos: Vector2 = randomize_spawning_location(origin)
	enemy.global_position = spawn_pos
	EventBus.enemy_spawned.emit(enemy, spawn_pos)
	return enemy

## Calculates a random direction vector for wandering.
func _get_random_direction(wander_length: float = 200.0) -> Vector2:
	return Vector2(
		randf_range(-wander_length, wander_length),
		randf_range(-wander_length, wander_length)
	).normalized()
