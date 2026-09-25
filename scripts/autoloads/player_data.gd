## PlayerData
## Autoload that stores and manages the player's core stats, experience,
## inventory, and lootable items. Acts as the central data store for the player.
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
## List of available stat names.
const STAT_NAMES = ["HP", "MP", "STR", "REC", "INT", "WIS", "DEX", "LUC"]
## List of available stat names without HP and MP.
const STAT_NAMES_NO_FLT = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]
## Number of stat points awarded per level up.
const POINTS_STATS_PER_LEVEL = 5


# ─── Private Variables ───────────────────────────────────────────────────────
var __player_level: int = 1
var __current_xp: int = 0
var __total_xp_to_next_level: int = 75
var __base_stats: CharacterStats = null
var __lootable_items: Array[DataItem] = []
var __inventory_items: Array[DataItem] = []
var __equipable_items: Dictionary = {
	"HELMET": null,
	"CHEST": null,
	"GLOVES": null,
	"BOOTS": null,
	"SHIELD": null,
	"WEAPON": null,
	"RING": null,
	"AMULET": null,
	"CLOAK": null,
	"PET": null
}

var __potions: Dictionary = {
	"HEALTH": [],
	"MANA": [],
}

var __available_gold: int = 1000

# ─── XP & Leveling ───────────────────────────────────────────────────────────
## Sets the current player level.
func set_player_level(new_level: int) -> void:
	__player_level = new_level

## Gets the current player level.
func get_player_level() -> int:
	return __player_level

## Sets the current experience points.
func set_current_xp(new_xp: int) -> void:
	__current_xp = new_xp
	EventBus.hero_xp_changed.emit(__current_xp, __total_xp_to_next_level)

## Gets the current experience points.
func get_current_xp() -> int:
	return __current_xp

## Sets the total experience points needed for the next level.
func set_total_xp_to_next_level(new_xp: int) -> void:
	__total_xp_to_next_level = new_xp
	EventBus.hero_xp_changed.emit(__current_xp, __total_xp_to_next_level)

## Gets the total experience points needed for the next level.
func get_total_xp_to_next_level() -> int:
	return __total_xp_to_next_level

# ─── Inventory & Items ───────────────────────────────────────────────────────
## Adds an item to the list of lootable items currently in range.
func add_lootable_item(item: DataItem) -> void:
	__lootable_items.append(item)

## Removes an item from the list of lootable items.
func remove_lootable_item(item: DataItem) -> void:
	__lootable_items.erase(item)

## Adds an item to the player's inventory.
func add_inventory_item(item: DataItem) -> void:
	__inventory_items.append(item)

## Removes an item from the player's inventory.
func remove_inventory_item(item: DataItem) -> void:
	__inventory_items.erase(item)


# ─── Equipment ───────────────────────────────────────────────────────────────
func get_equipements() -> Dictionary:
	return __equipable_items

## TODO: use enums instead of hard coded names
## Adds an equipable item to the player's equipment.
func add_equipable_item(item: EquipableItem) -> void:
	if is_instance_valid(item):
		var eq_type = item.equipment_type.to_upper()
		if "SWORD" in eq_type or "AXE" in eq_type or "MACE" in eq_type or "BOW" in eq_type or "CROSSBOW" in eq_type or "DAGGER" in eq_type or "WEAPON" in eq_type:
			__equipable_items["WEAPON"] = item
		elif eq_type in __equipable_items:
			__equipable_items[eq_type] = item
		elif eq_type == "HEAD":
			__equipable_items["HELMET"] = item
		elif eq_type == "ARMOR":
			__equipable_items["CHEST"] = item
		elif eq_type == "FEET":
			__equipable_items["BOOTS"] = item

## TODO: use enums instead of hard coded names
## Removes an equipable item from the player's equipment.
func remove_equipable_item(item: EquipableItem) -> void:
	if is_instance_valid(item):
		var eq_type = item.equipment_type.to_upper()
		if "SWORD" in eq_type or "AXE" in eq_type or "MACE" in eq_type or "BOW" in eq_type or "CROSSBOW" in eq_type or "DAGGER" in eq_type or "WEAPON" in eq_type:
			__equipable_items["WEAPON"] = null
		elif eq_type in __equipable_items:
			__equipable_items[eq_type] = null
		elif eq_type == "HEAD":
			__equipable_items["HELMET"] = null
		elif eq_type == "ARMOR":
			__equipable_items["CHEST"] = null
		elif eq_type == "FEET":
			__equipable_items["BOOTS"] = null

# ─── Potions ───────────────────────────────────────────────────────────────
func add_potion(potion: ConsumableItem) -> void:
	var p_type = potion.potion_type.to_upper()
	if p_type in __potions:
		__potions[p_type].append(potion)

func remove_potion_from_list(potion: ConsumableItem) -> void:
	var p_type = potion.potion_type.to_upper()
	if p_type in __potions:
		__potions[p_type].erase(potion)

func get_available_gold():
	return __available_gold

func set_available_gold(new_gold: int):
	__available_gold = new_gold