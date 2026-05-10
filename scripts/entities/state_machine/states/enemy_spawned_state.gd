extends State
class_name EnemySpawnedState

func enter() -> void:
	if actor is Enemy and actor.enemy_params:
		actor._load_params(actor.enemy_params)
		actor.on_spawned.connect(_on_spawned)
		transitioned.emit("idlestate")

func _on_spawned(_spawn_position: Vector2):
	actor.spawn_position = _spawn_position
