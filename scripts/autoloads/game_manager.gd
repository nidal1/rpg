## GameManager
## Manages core game loops, leveling, experience, and global interactions.
extends Node

# ─── Public Variables ────────────────────────────────────────────────────────
## Reference to the current player character.
var player_ref: Character = null
## Modifier applied to the required XP for each subsequent level.
var level_scaler: float = 1.2
## Range within which items drop from defeated enemies.
var drop_range: float = 50.0
## StatsManager instance for managing stats logic
var stats_manager: StatsManager = StatsManager.new()

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.stat_allocated.connect(stats_manager.add_stat_point)
	EventBus.stat_deallocated.connect(stats_manager.sub_stat_point)
	EventBus.save_stats_points.connect(stats_manager.save_stats)
	EventBus.cancel_stats_points.connect(stats_manager.cancel_stats)
	EventBus.lootable_item_added.connect(_on_lootable_item_added)
	EventBus.lootable_item_removed.connect(_on_lootable_item_removed)
	EventBus.selected_lootable_items_picked_up.connect(_on_selected_lootable_items_picked_up)
	EventBus.item_dropped_from_inventory.connect(_on_item_dropped_from_inventory)
	EventBus.equip_item.connect(_on_equip_item)
	EventBus.item_unequipped.connect(_on_item_unequipped)
	EventBus.potions_unequipped.connect(_on_potion_unequipped)
	EventBus.potions_consumed.connect(_on_potion_consumed)
	EventBus.buy_item.connect(_on_buy_item)

# ─── Public Methods ──────────────────────────────────────────────────────────
## Registers the player with the Game Manager and initializes data.
func register_player(player: Character) -> void:
	player_ref = player
	var character_stats = player_ref.character_class.get_class_stats()
	stats_manager.initialize(character_stats)

## Adds experience points to the player.
func add_xp(amount: int) -> void:
	var current_xp = PlayerData.get_current_xp() + amount
	PlayerData.set_current_xp(current_xp)

	if current_xp >= PlayerData.get_total_xp_to_next_level():
		level_up()

## Handles the level up logic for the player.
func level_up() -> void:
	var player_level = PlayerData.get_player_level() + 1
	PlayerData.set_player_level(player_level)
	stats_manager.update_available_points_on_level_up()
	scaling_level_up()
	StatsData.get_stats().update_current_health_and_mana()
	EventBus.level_up.emit()

## Scales the required XP for the next level up.
func scaling_level_up() -> void:
	var next_level: int = PlayerData.get_player_level()
	var new_required_xp: int = ProgressionManager.get_required_xp_for_level(next_level, level_scaler)
	PlayerData.set_total_xp_to_next_level(new_required_xp)

## Randomizes a position near the specified position within the drop range.
func randomize_drop_position(position: Vector2, _drop_range: float = drop_range) -> Vector2:
	return position + Vector2(
		randf_range(-_drop_range, _drop_range),
		randf_range(-_drop_range, _drop_range)
	)

## Spawns items dropped by a defeated enemy into the drop zone.
func spawn_enemy_items(enemy: Enemy) -> void:
	var drop_zone = enemy.get_parent().get_drop_zone()
	if drop_zone:
		var drops = enemy._drop_item()
		for drop in drops:
			var random_position = randomize_drop_position(enemy.global_position)
			drop_zone.call_deferred("add_child", drop)
			drop.set_deferred("global_position", random_position)

func drop_item(item: DataItem) -> void:
	var drop_scene = load("res://scenes/entities/items/drop.tscn").instantiate()
	var drop_zone_nodes = get_tree().get_nodes_in_group("enemies_spawner")
	if drop_zone_nodes.size() > 0:
		var drop_zone = drop_zone_nodes[0].get_drop_zone()
		if drop_zone:
			var random_position = randomize_drop_position(player_ref.global_position)
			drop_scene.item = item
			drop_zone.add_child(drop_scene)
			drop_scene.global_position = random_position

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_enemy_died(enemy: Enemy) -> void:
	var enemy_lvl: int = enemy.enemy_level if "enemy_level" in enemy else 1
	var enemy_rank = enemy.enemy_rank if "enemy_rank" in enemy else ProgressionManager.EnemyRank.NORMAL
	var xp_reward: int = ProgressionManager.get_enemy_xp_yield(enemy_lvl, enemy_rank, PlayerData.get_player_level())
	
	if xp_reward > 0:
		add_xp(xp_reward)
	spawn_enemy_items(enemy)

func _on_lootable_item_added(item: DataItem) -> void:
	PlayerData.add_lootable_item(item)
	EventBus.display_lootable_item_hover_info.emit(item)

func _on_lootable_item_removed(item: DataItem) -> void:
	PlayerData.remove_lootable_item(item)
	EventBus.hide_lootable_item_hover_info.emit(item)

func _on_selected_lootable_items_picked_up(slots: Array[DataItem]) -> void:
	for slot in slots:
		if slot != null:
			PlayerData.add_inventory_item(slot)
	
	EventBus.items_added_to_inventory.emit(slots)

func _on_item_dropped_from_inventory(item: DataItem) -> void:
	drop_item(item)
	PlayerData.remove_inventory_item(item)

func _on_equip_item(inventory_slot: InventorySlot) -> void:
	var item = inventory_slot.get_item()
	if item is EquipableItem:
		var eq = item as EquipableItem
		## TODO: popup system message
		if eq.required_level > PlayerData.get_player_level(): return

		var eq_player_class = eq.player_class
		var player_class = player_ref.character_class.PlayerType.keys()[player_ref.character_class.player_type]
		if eq_player_class == "" or eq_player_class.to_upper() == "ALL" or (player_ref and player_ref.character_class and eq_player_class.to_upper() in player_class):
			var item_type = eq.equipment_type.to_upper()
			if not PlayerData.get_equipements().get(item_type):
				PlayerData.add_equipable_item(eq)
				stats_manager.calculate_equipment_bonus(eq)
				PlayerData.remove_inventory_item(eq)
				EventBus.item_equipped.emit(inventory_slot)
			else:
				var old_item = PlayerData.get_equipements().get(item_type)
				PlayerData.remove_equipable_item(old_item)
				stats_manager.calculate_equipment_bonus(old_item, "unequip")

				PlayerData.add_equipable_item(eq)
				stats_manager.calculate_equipment_bonus(eq)

				PlayerData.add_inventory_item(old_item)
				PlayerData.remove_inventory_item(eq)

				EventBus.item_equipped.emit(inventory_slot)
				inventory_slot.clear_slot()
				inventory_slot.set_item(old_item)

			if player_ref and player_ref.character_class:
				player_ref.character_class.set_class_stats(StatsData.get_stats())
			EventBus.stats_updated.emit(StatsData)

	elif item is ConsumableItem:
		var potion = item as ConsumableItem
		PlayerData.add_potion(potion)
		PlayerData.remove_inventory_item(potion)
		EventBus.potions_added_to_list.emit(potion)
		var _items_to_remove: Array[DataItem] = [potion]
		EventBus.items_removed_from_inventory.emit(_items_to_remove)

func _on_item_unequipped(item: EquipableItem) -> void:
	if item is EquipableItem:
		PlayerData.add_inventory_item(item)
		stats_manager.calculate_equipment_bonus(item, "unequip")
		PlayerData.remove_equipable_item(item)
		
		var _items_to_add: Array[DataItem] = [item]
		EventBus.items_added_to_inventory.emit(_items_to_add)
		if player_ref and player_ref.character_class:
			player_ref.character_class.set_class_stats(StatsData.get_stats())
		EventBus.stats_updated.emit(StatsData)

func _on_potion_unequipped(potion: ConsumableItem) -> void:
	PlayerData.add_inventory_item(potion)
	PlayerData.remove_potion_from_list(potion)

	var _items_to_add: Array[DataItem] = [potion]
	EventBus.items_added_to_inventory.emit(_items_to_add)

## TODO: use enums instead of hard coded names
func _on_potion_consumed(potion: ConsumableItem):
	var heal_amount = float(potion.heal_amount)
	var p_type = potion.potion_type.to_upper()

	if p_type == "HEALTH":
		StatsData.get_stats().set_current_hp(StatsData.get_stats().get_current_hp() + heal_amount)
	elif p_type == "MANA":
		StatsData.get_stats().set_current_mp(StatsData.get_stats().get_current_mp() + heal_amount)
	
	EventBus.stats_updated.emit(StatsData)

func _on_buy_item(_value: float, _data_item: DataItem):
	var _item_price = _data_item.price
	print("item_price: ",_item_price)
	var _total_price = _item_price * int(_value)
	print(" total_price: ", _total_price)
	var player_available_gold = PlayerData.get_available_gold()
	print("player_available_gold: ", player_available_gold)
	if player_available_gold >= _total_price:
		var remaning = player_available_gold - _total_price
		print("remaning: ", remaning)
		PlayerData.set_available_gold(remaning)
		PlayerData.add_inventory_item(_data_item)
		var _items_to_add: Array[DataItem] = [_data_item]
		EventBus.items_added_to_inventory.emit(_items_to_add)
		EventBus.udpate_available_gold.emit(remaning)
