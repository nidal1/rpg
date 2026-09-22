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
var __lootable_items: Array[Item] = []
var __inventory_items: Array[Item] = []
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

# ─── Initialization ──────────────────────────────────────────────────────────
## Initializes the player data using the base stats from their class.
# func initialize(stats: CharacterStats) -> void:
# 	__base_stats = stats.get_instance()
# 	if not stats_manager:
# 		stats_manager = StatsManager.new()
# 	stats_manager.initialize(__base_stats)
# 	EventBus.stat_points_available_changed.emit(stats_manager.available_points)

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
func add_lootable_item(item: Item) -> void:
	__lootable_items.append(item)

## Removes an item from the list of lootable items.
func remove_lootable_item(item: Item) -> void:
	__lootable_items.erase(item)

## Adds an item to the player's inventory.
func add_inventory_item(item: Item) -> void:
	__inventory_items.append(item)

## Removes an item from the player's inventory.
func remove_inventory_item(item: Item) -> void:
	__inventory_items.erase(item)


# ─── Equipment ───────────────────────────────────────────────────────────────
func get_equipements() -> Dictionary:
	return __equipable_items

## Adds an equipable item to the player's equipment.
func add_equipable_item(item: Equipable) -> void:
	if is_instance_valid(item):
		if item is Weapon:
			__equipable_items["WEAPON"] = item
			return
		if item is Armor:
			__equipable_items[Armor.ArmorType.keys()[item.armor_type]] = item
			return


## Removes an equipable item from the player's equipment.
func remove_equipable_item(item: Equipable) -> void:
	if item is Weapon:
		if is_instance_valid(__equipable_items["WEAPON"]):
			__equipable_items["WEAPON"] = null
		return
	if item is Armor:
		if is_instance_valid(__equipable_items[Armor.ArmorType.keys()[item.armor_type]]):
			__equipable_items[Armor.ArmorType.keys()[item.armor_type]] = null
		return


# ─── Potions ───────────────────────────────────────────────────────────────
func add_potion(potion: Potion) -> void:
	var potion_effect = potion.get_potion_effect()
	if potion_effect["potion_type"] == Potion.PotionType.HEALTH_POTION:
		__potions["HEALTH"].append(potion)
		return
	if potion_effect["potion_type"] == Potion.PotionType.MANA_POTION:
		__potions["MANA"].append(potion)
		return

func remove_potion_from_list(potion: Potion) -> void:
	var potion_effect = potion.get_potion_effect()
	if potion_effect["potion_type"] == Potion.PotionType.HEALTH_POTION:
		__potions["HEALTH"].erase(potion)
		return
	if potion_effect["potion_type"] == Potion.PotionType.MANA_POTION:
		__potions["MANA"].erase(potion)
		return


func use_health_potion() -> void:
	if __potions["HEALTH"] > 0:
		__potions["HEALTH"] -= 1
		EventBus.health_potions_changed.emit(__potions["HEALTH"])

func use_mana_potion() -> void:
	if __potions["MANA"] > 0:
		__potions["MANA"] -= 1
		EventBus.mana_potions_changed.emit(__potions["MANA"])

func get_available_gold():
	return __available_gold

func set_available_gold(new_gold: int):
	__available_gold = new_gold