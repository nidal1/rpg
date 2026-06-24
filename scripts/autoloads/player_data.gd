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

# ─── Public Variables ────────────────────────────────────────────────────────
## Tracks whether stat allocation points have been saved.
var allocate_point_saved: bool = false

# ─── Private Variables ───────────────────────────────────────────────────────
var __player_level: int = 1
var __current_xp: int = 0
var __total_xp_to_next_level: int = 75
var __stat_points_available: int = 0
var __temp_stat_points_available: int = 0
var __base_stats: CharacterStats = null
var __allocated_stats: Dictionary = {
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0
}
var __temp_allocated_stats: Dictionary = __allocated_stats.duplicate()
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

# ─── Initialization ──────────────────────────────────────────────────────────
## Initializes the player data using the base stats from their class.
func initialize(stats: CharacterStats) -> void:
	__base_stats = stats.get_instance()
	__allocated_stats = stats.get_allocated_stats()
	__temp_allocated_stats = __allocated_stats.duplicate()

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

## Gets the current experience points.
func get_current_xp() -> int:
	return __current_xp

## Sets the total experience points needed for the next level.
func set_total_xp_to_next_level(new_xp: int) -> void:
	__total_xp_to_next_level = new_xp

## Gets the total experience points needed for the next level.
func get_total_xp_to_next_level() -> int:
	return __total_xp_to_next_level

# ─── Stat Allocation ─────────────────────────────────────────────────────────
## Sets the number of available stat points.
func set_stat_points_available(new_points: int) -> void:
	__stat_points_available = new_points

## Gets the number of available stat points.
func get_stat_points_available() -> int:
	return __stat_points_available

## Sets the allocated value for a specific stat.
func set_allocated_stat(stat_name: String, stat_value: int) -> void:
	__allocated_stats[stat_name] = stat_value

## Gets the allocated value for a specific stat.
func get_allocated_stat(stat_name: String) -> int:
	return __allocated_stats[stat_name]

## Returns a copy of the allocated stats dictionary.
func get_stat_alloc() -> Dictionary:
	return __allocated_stats.duplicate()

## Updates the available points after a level up.
func update_available_points() -> void:
	set_stat_points_available(get_stat_points_available() + POINTS_STATS_PER_LEVEL)
	__temp_stat_points_available = __stat_points_available

## Adds a stat point to the specified stat.
func add_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() <= 0 or allocate_point_saved or _stat_name not in STAT_NAMES_NO_FLT:
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) + 1)
	set_stat_points_available(get_stat_points_available() - 1)
	return true

## Subtracts a stat point from the specified stat.
func sub_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() >= __temp_stat_points_available or allocate_point_saved or _stat_name not in STAT_NAMES_NO_FLT:
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) - 1)
	set_stat_points_available(get_stat_points_available() + 1)
	return true

## Saves the currently allocated stats.
func save_stats() -> void:
	if __stat_points_available <= 0:
		allocate_point_saved = true
	
	__temp_stat_points_available = __stat_points_available
	__temp_allocated_stats = __allocated_stats.duplicate()

## Cancels the current stat allocation and reverts to the last saved state.
func cancel_stats() -> void:
	__stat_points_available = __temp_stat_points_available
	__allocated_stats = __temp_allocated_stats.duplicate()
	allocate_point_saved = false

func get_base_stats() -> CharacterStats:
	return __base_stats

	
# ─── Computed Stats ──────────────────────────────────────────────────────────
## Gets the total value of a stat including base and allocated points.
func get_total(_stat_name: String) -> int:
	var base_value: int = 0
	match _stat_name:
		"STR": base_value = __base_stats.STR
		"REC": base_value = __base_stats.REC
		"INT": base_value = __base_stats.INT
		"WIS": base_value = __base_stats.WIS
		"DEX": base_value = __base_stats.DEX
		"LUC": base_value = __base_stats.LUC
	return base_value + __allocated_stats.get(_stat_name, 0)

## Converts allocated base stats to a dictionary format.
func from_allocated_stats_to_dict() -> Dictionary:
	return {
		"STR": __base_stats.STR,
		"REC": __base_stats.REC,
		"INT": __base_stats.INT,
		"WIS": __base_stats.WIS,
		"DEX": __base_stats.DEX,
		"LUC": __base_stats.LUC,
	}

func get_base_weapon_power() -> float:
	return __base_stats.get_total("weapon_power")

func get_base_armor_defense() -> float:
	return __base_stats.get_total("armor_defense")

func get_base_armor_resist() -> float:
	return __base_stats.get_total("armor_resist")

func set_base_weapon_power(power: float) -> void:
	__base_stats.weapon_power = power

func set_base_armor_defense(value: float) -> void:
	__base_stats.armor_defense = value

func set_base_armor_resist(resist: float) -> void:
	__base_stats.armor_resist = resist

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

## Calculate equipement stats bonus 
## args { equipement: Equipable, operation: "equip" or "unequip"}
func calculate_equipement_stats_bonus(equipement: Equipable, operation: String = "equip"):
	if is_instance_valid(equipement):
		var effective_stats_breakdown = equipement.get_effective_stats_breakdown()

		for s in effective_stats_breakdown:
			var base = effective_stats_breakdown[s]["base"]
			var gem = effective_stats_breakdown[s]["gem"]
			
			if operation == "equip":
				__base_stats.add_stat_bonus(s, base + gem)
			elif operation == "unequip":
				__base_stats.remove_stat_bonus(s, base + gem)

		if equipement is Weapon:
			if operation == "equip":
				__base_stats.add_stat_bonus("weapon_power", equipement.base_attack_power)
			if operation == "unequip":
				__base_stats.remove_stat_bonus("weapon_power", equipement.base_attack_power)
			return
		
		if equipement is Armor:
			if operation == "equip":
				__base_stats.add_stat_bonus("armor_defense", equipement.base_defense)
				__base_stats.add_stat_bonus("armor_resist", equipement.base_resist)
			if operation == "unequip":
				__base_stats.remove_stat_bonus("armor_defense", equipement.base_defense)
				__base_stats.remove_stat_bonus("armor_resist", equipement.base_resist)
			return
