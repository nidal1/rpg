## EnemiesSpawner
## Manages the periodic spawning of enemies within a specified radius
## and handles the removal of dropped items from the game world.
extends Node2D

# ─── Exported Variables ──────────────────────────────────────────────────────
## The point around which enemies will be spawned.
@export var spawn_point: Marker2D
## An array of enemy scenes that can be spawned.
@export var enemies: Array[PackedScene]
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
	for _i in range(enemies.size()):
		_spawn_enemy()
	EventBus.selected_lootable_items_picked_up.connect(remove_selected_drops)

# ─── Public Methods ──────────────────────────────────────────────────────────
## Calculates a random spawning location within the spawn circle radius.
func randomize_spawning_location(spawn_position: Vector2) -> Vector2:
	return spawn_position + Vector2(
		randf_range(-spawn_circle_radius, spawn_circle_radius),
		randf_range(-spawn_circle_radius, spawn_circle_radius)
	)

## Returns the node acting as the drop zone for items.
func get_drop_zone() -> Node:
	return drop_zone

## Removes an enemy from the spawner's list and starts the respawn timer.
func remove_enemy(enemy: Enemy) -> void:
	enemies.erase(enemy)
	# wait certain time and spawn new enemy
	await get_tree().create_timer(respawn_cd).timeout
	_spawn_enemy()

## Removes the physical representations of items that the player picked up.
func remove_selected_drops(items: Array[Item]) -> void:
	for drop in drop_zone.get_children():
		if drop.item in items:
			drop.queue_free()

# ─── Private Methods ─────────────────────────────────────────────────────────
## Instantiates a random enemy from the list and places it in the world.
func _spawn_enemy() -> void:
	var enemy = enemies[randi() % enemies.size()].instantiate()
	add_child(enemy)
	enemy.global_position = randomize_spawning_location(global_position)
	EventBus.enemy_spawned.emit(enemy, enemy.global_position)

## Calculates a random direction vector for wandering.
func _get_random_direction(wander_length: float = 200) -> Vector2:
	return Vector2(
		randf_range(-wander_length, wander_length),
		randf_range(-wander_length, wander_length)
	).normalized()
