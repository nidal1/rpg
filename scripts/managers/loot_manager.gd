## LootManager
## Manages loot drops, spawning, and pickup events.
class_name LootManager
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
const DEFAULT_DROP_RANGE: float = 50.0

# ─── Public Methods ──────────────────────────────────────────────────────────
## Randomizes a position near the specified position within the drop range.
func get_random_drop_position(base_position: Vector2, drop_range: float = DEFAULT_DROP_RANGE) -> Vector2:
	return base_position + Vector2(
		randf_range(-drop_range, drop_range),
		randf_range(-drop_range, drop_range)
	)

## Spawns items dropped by a defeated enemy into the drop zone.
func spawn_enemy_drops(enemy: Enemy) -> void:
	var drop_zone = enemy.get_parent().get_drop_zone()
	if drop_zone:
		var drops = enemy._drop_item()
		for drop in drops:
			var random_position = get_random_drop_position(enemy.global_position)
			drop_zone.call_deferred("add_child", drop)
			drop.set_deferred("global_position", random_position)

## Drops an item at the player's position.
func drop_item_at_player(item: DataItem, player_position: Vector2, scene_tree: SceneTree) -> void:
	var drop_scene = load("res://scenes/entities/items/drop.tscn").instantiate()
	var drop_zone_nodes = scene_tree.get_nodes_in_group("enemies_spawner")
	if drop_zone_nodes.size() > 0:
		var drop_zone = drop_zone_nodes[0].get_drop_zone()
		if drop_zone:
			var random_position = get_random_drop_position(player_position)
			drop_scene.item = item
			drop_zone.add_child(drop_scene)
			drop_scene.global_position = random_position

## Handles lootable item added event.
func handle_lootable_item_added(item: DataItem) -> void:
	PlayerData.add_lootable_item(item)
	EventBus.display_lootable_item_hover_info.emit(item)

## Handles lootable item removed event.
func handle_lootable_item_removed(item: DataItem) -> void:
	PlayerData.remove_lootable_item(item)
	EventBus.hide_lootable_item_hover_info.emit(item)

## Handles multiple items being picked up.
func handle_items_picked_up(slots: Array[DataItem]) -> void:
	for slot in slots:
		if slot != null:
			PlayerData.add_inventory_item(slot)
	EventBus.items_added_to_inventory.emit(slots)

## Handles item dropped from inventory.
func handle_inventory_item_dropped(item: DataItem, player_position: Vector2, scene_tree: SceneTree) -> void:
	drop_item_at_player(item, player_position, scene_tree)
	PlayerData.remove_inventory_item(item)
