extends Node2D

@export var spawn_point: Marker2D


@export var enemies: Array[PackedScene]
@export var spawn_circle_radius: float = 100.0
@export var respawn_cd: float = 5.0
@export var wander_cd_time: float = 20.0


func _ready() -> void:
	for _i in range(enemies.size()):
		_spawn_enemy()

func _spawn_enemy() -> void:
	var enemy = enemies[randi() % enemies.size()].instantiate()
	add_child(enemy)
	enemy.global_position = randomize_spawning_location(global_position)
	enemy.on_spawned.emit(enemy.global_position)


func randomize_spawning_location(spawn_position: Vector2) -> Vector2:
	return spawn_position + Vector2(
		randf_range(-spawn_circle_radius, spawn_circle_radius),
		randf_range(-spawn_circle_radius, spawn_circle_radius)
	)

func _get_random_direction(wander_length: float = 200) -> Vector2:
	return Vector2(
		randf_range(-wander_length, wander_length),
		randf_range(-wander_length, wander_length)
	).normalized()

func remove_enemy(enemy: Enemy) -> void:
	enemies.erase(enemy)
	# wait certain time and spawn new enemy
	await get_tree().create_timer(respawn_cd).timeout
	_spawn_enemy()
