extends Node2D

@export var spawn_point: Marker2D


@export var enemies: Array[PackedScene]
@export var spawn_circle_radius: float = 100.0

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
