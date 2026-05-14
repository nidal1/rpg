# enemy_spawned_state.gd
extends State
class_name EnemySpawnedState

func enter() -> void:
	if actor.enemy_params:
		actor._load_params(actor.enemy_params)
		actor.on_spawned.connect(_on_spawned)
		transitioned.emit("enemyidlestate")

func _on_spawned(_spawn_position: Vector2):
	actor.spawn_position = _spawn_position
	actor.on_died.connect(_on_enemy_died)


func _on_enemy_died():
	# remove this enemy from enemies spawner
	var enemies_spawner = get_tree().get_first_node_in_group("enemies_spawner")
	if enemies_spawner:
		enemies_spawner.remove_enemy(actor)