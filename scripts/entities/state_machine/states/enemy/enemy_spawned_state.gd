## EnemySpawnedState
## Initial state for enemies upon spawning. Sets up parameters and signals.
extends State
class_name EnemySpawnedState

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func enter() -> void:
	if actor.enemy_params:
		actor._load_params(actor.enemy_params)
		EventBus.enemy_died.connect(_on_enemy_died)
		EventBus.enemy_spawned.connect(_on_spawned)
		transitioned.emit("enemyidlestate")

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_spawned(enemy: Enemy, _spawn_position: Vector2) -> void:
	if enemy != actor: return
	enemy.spawn_position = _spawn_position

func _on_enemy_died(enemy: Enemy) -> void:
	if enemy != actor: return
	# remove this enemy from enemies spawner
	var enemies_spawner = get_tree().get_first_node_in_group("enemies_spawner")
	if enemies_spawner:
		enemies_spawner.remove_enemy(enemy)