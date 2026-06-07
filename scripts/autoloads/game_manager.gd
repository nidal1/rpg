extends Node

var player_ref: Character = null

var level_scaler = 1.2
var drop_range: float = 50.0


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.stat_allocated.connect(allocate_point)
	EventBus.stat_deallocated.connect(deallocate_point)
	EventBus.save_stats_points.connect(save_stats_points)
	EventBus.cancel_stats_points.connect(cancel_stats_points)
	EventBus.lootable_item_added.connect(_on_lootable_item_added)
	EventBus.lootable_item_removed.connect(_on_lootable_item_removed)


func register_player(player: Character) -> void:
	player_ref = player
	PlayerData.initialize(player.character_class)
	EventBus.initialize_hero_stats_ui.emit(player.character_class)

# ─── XP & Leveling ───────────────────────────────────
func _on_enemy_died(enemy: Enemy) -> void:
	var xp_reward = enemy.enemy_params.xp_reward
	if xp_reward > 0:
		add_xp(xp_reward)
	spawn_enemy_items(enemy)


func add_xp(amount: int) -> void:
	var current_xp = PlayerData.get_current_xp() + amount
	PlayerData.set_current_xp(current_xp)
	EventBus.xp_changed.emit(current_xp)
	if current_xp >= PlayerData.get_total_xp_to_next_level():
		level_up()

func level_up() -> void:
	var player_level = PlayerData.get_player_level() + 1
	PlayerData.set_player_level(player_level)
	PlayerData.update_available_points()

	scaling_level_up()
	EventBus.level_up.emit()

func scaling_level_up() -> void:
	PlayerData.set_total_xp_to_next_level(int(level_scaler * PlayerData.get_total_xp_to_next_level()))

# ─── Stat Allocation ─────────────────────────────────
func allocate_point(stat_name: String) -> void:
	if PlayerData.add_stat_point(stat_name):
		EventBus.stats_updated.emit()

func deallocate_point(stat_name: String) -> void:
	if PlayerData.sub_stat_point(stat_name):
		EventBus.stats_updated.emit()

func save_stats_points():
	PlayerData.save_stats()
	EventBus.stats_updated.emit()

func cancel_stats_points():
	PlayerData.cancel_stats()
	EventBus.stats_updated.emit()


# ─── Drop Items ─────────────────────────────────
func randomize_drop_position(position: Vector2) -> Vector2:
	return position + Vector2(
		randf_range(-drop_range, drop_range),
		randf_range(-drop_range, drop_range)
	)

func spawn_enemy_items(enemy: Enemy) -> void:
	var drop_zone = get_tree().get_first_node_in_group("enemies_spawner").get_drop_zone()
	if drop_zone:
		var drops = enemy._drop_item()
		for drop in drops:
			var random_position = randomize_drop_position(enemy.global_position)
			drop_zone.call_deferred("add_child", drop)
			drop.set_deferred("global_position", random_position)

func _on_lootable_item_added(item: Item) -> void:
	print("picked item nameL: ", item.item_name)
	PlayerData.add_lootable_item(item)
	EventBus.display_lootable_item_hover_info.emit(item)

func _on_lootable_item_removed(item: Item) -> void:
	print("removed item nameL: ", item.item_name)
	PlayerData.remove_lootable_item(item)
	EventBus.hide_lootable_item_hover_info.emit(item)
