## EquipmentManager
## Manages equipment, consumables, and merchant transactions.
class_name EquipmentManager
extends Node

# ─── Public Methods ──────────────────────────────────────────────────────────
## Handles equipping an item from inventory slot.
func equip_item_from_slot(inventory_slot: InventorySlot, player_ref: Character, stats_manager: StatsManager) -> void:
	var item = inventory_slot.get_item()
	if item is EquipableItem:
		_equip_equipable_item(item, inventory_slot, player_ref, stats_manager)
	elif item is ConsumableItem:
		_equip_consumable_item(item, inventory_slot)

## Handles unequipping an item.
func unequip_item(item: EquipableItem, player_ref: Character, stats_manager: StatsManager) -> void:
	if item is EquipableItem:
		PlayerData.add_inventory_item(item)
		stats_manager.calculate_equipment_bonus(item, "unequip")
		PlayerData.remove_equipable_item(item)

		var items_to_add: Array[DataItem] = [item]
		EventBus.items_added_to_inventory.emit(items_to_add)

		if player_ref and player_ref.character_class:
			player_ref.character_class.set_class_stats(StatsData.get_stats())
		EventBus.stats_updated.emit(StatsData)

## Handles unequipping a potion.
func unequip_potion(potion: ConsumableItem) -> void:
	PlayerData.add_inventory_item(potion)
	PlayerData.remove_potion_from_list(potion)

	var items_to_add: Array[DataItem] = [potion]
	EventBus.items_added_to_inventory.emit(items_to_add)

## Handles consuming a potion.
func consume_potion(potion: ConsumableItem) -> void:
	var heal_amount = float(potion.heal_amount)
	var p_type = potion.potion_type.to_upper()

	if p_type == "HEALTH":
		StatsData.get_stats().set_current_hp(StatsData.get_stats().get_current_hp() + heal_amount)
	elif p_type == "MANA":
		StatsData.get_stats().set_current_mp(StatsData.get_stats().get_current_mp() + heal_amount)

	EventBus.stats_updated.emit(StatsData)

## Handles purchasing an item from merchant.
func purchase_item(quantity: float, item: DataItem) -> void:
	var item_price = item.price
	var total_price = item_price * int(quantity)
	var player_gold = PlayerData.get_available_gold()

	if player_gold >= total_price:
		var remaining = player_gold - total_price
		PlayerData.set_available_gold(remaining)
		PlayerData.add_inventory_item(item)

		var items_to_add: Array[DataItem] = [item]
		EventBus.items_added_to_inventory.emit(items_to_add)
		EventBus.udpate_available_gold.emit(remaining)

# ─── Private Methods ─────────────────────────────────────────────────────────
func _equip_equipable_item(eq: EquipableItem, inventory_slot: InventorySlot, player_ref: Character, stats_manager: StatsManager) -> void:
	# Level requirement check
	if eq.required_level > PlayerData.get_player_level():
		return

	# Class requirement check
	var eq_player_class = eq.player_class
	var player_class = player_ref.character_class.PlayerType.keys()[player_ref.character_class.player_type]
	if not (eq_player_class == "" or eq_player_class.to_upper() == "ALL" or eq_player_class.to_upper() in player_class):
		return

	var item_type = eq.equipment_type.to_upper()

	# Empty slot - equip directly
	if not PlayerData.get_equipements().get(item_type):
		PlayerData.add_equipable_item(eq)
		stats_manager.calculate_equipment_bonus(eq)
		PlayerData.remove_inventory_item(eq)
		EventBus.item_equipped.emit(inventory_slot)
	else:
		# Slot occupied - swap items
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

func _equip_consumable_item(potion: ConsumableItem, inventory_slot: InventorySlot) -> void:
	PlayerData.add_potion(potion)
	PlayerData.remove_inventory_item(potion)
	EventBus.potions_added_to_list.emit(potion)

	var items_to_remove: Array[DataItem] = [potion]
	EventBus.items_removed_from_inventory.emit(items_to_remove)
