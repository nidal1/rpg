extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
## List of available stat names.
const STAT_NAMES = ["HP", "MP", "STR", "REC", "INT", "WIS", "DEX", "LUC"]
## List of available stat names without HP and MP.
const STAT_NAMES_NO_FLT = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]
## Number of stat points awarded per level up.
const POINTS_STATS_PER_LEVEL = 5


# ─── Private Variables ───────────────────────────────────────────────────────
var __base_stats: Dictionary = {
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0,
	"HP": 0,
	"MP": 0,
}

var __bonus_stats: Dictionary = {
	"max_health": 0.0,
	"max_mana": 0.0,
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0,
	"weapon_power": 0.0,
	"armor_defense": 0.0,
	"armor_resist": 0.0
}

var __passive_stats: Dictionary = {
	"HP": 0.0,
	"MP": 0.0,
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0,
	"weapon_power": 0.0,
	"armor_defense": 0.0,
	"armor_resist": 0.0
}

var __buff_stats: Dictionary = {
	"HP": 0.0,
	"MP": 0.0,
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0,
	"weapon_power": 0.0,
	"armor_defense": 0.0,
	"armor_resist": 0.0
}

var __stat_points_available: int = 0
var __temp_stat_points_available: int = 0
var __allocate_point_saved: bool = false
var __allocated_stats: Dictionary = {
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0
}
var __temp_allocated_stats: Dictionary = {}
var bonus_stats: Dictionary = {}

func initialize_from_character_stats(cs: CharacterStats) -> void:
	if not cs: return
	__base_stats = cs.get_base_stats()
	__bonus_stats = cs.get_stats_bonus_dict()
	__allocated_stats = __base_stats.duplicate()
	__temp_allocated_stats = __allocated_stats.duplicate()

	update_current_health_and_mana()

func get_allocated_stat(key: String) -> int:
	return __allocated_stats.get(key, get_base_stat(key))

## Sets the allocated value for a specific stat.
func set_allocated_stat(stat_name: String, stat_value: int) -> void:
	__allocated_stats[stat_name] = stat_value

func get_temp_allocated_stat(key: String) -> int:
	return __temp_allocated_stats.get(key, get_base_stat(key))

## Gets the number of available stat points.
func get_stat_points_available() -> int:
	return __stat_points_available

## Sets the number of available stat points.
func set_stat_points_available(new_points: int) -> void:
	__stat_points_available = new_points

## Gets the number of available stat points.
func get_stat_temp_points_available() -> int:
	return __temp_stat_points_available

## Sets the number of available stat points.
func set_stat_temp_points_available(new_points: int) -> void:
	__temp_stat_points_available = new_points

func get_allocate_point_saved() -> bool:
	return __allocate_point_saved

func set_allocate_point_saved(saved: bool) -> void:
	__allocate_point_saved = saved

## Adds a stat point to the specified stat.
func add_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() <= 0 or _stat_name not in STAT_NAMES_NO_FLT:
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) + 1)
	sync_allocated_to_base()
	set_stat_points_available(get_stat_points_available() - 1)
	return true

## Subtracts a stat point from the specified stat.
func sub_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() >= __temp_stat_points_available or _stat_name not in STAT_NAMES_NO_FLT:
		return false
	if get_allocated_stat(_stat_name) <= get_temp_allocated_stat(_stat_name):
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) - 1)
	sync_allocated_to_base()
	set_stat_points_available(get_stat_points_available() + 1)
	return true

## Saves the currently allocated stats.
func save_stats() -> void:
	if __stat_points_available <= 0:
		__allocate_point_saved = true
	
	__temp_stat_points_available = __stat_points_available
	__temp_allocated_stats = __allocated_stats.duplicate()
	sync_allocated_to_base()

## Cancels the current stat allocation and reverts to the last saved state.
func cancel_stats() -> void:
	__stat_points_available = __temp_stat_points_available
	__allocated_stats = __temp_allocated_stats.duplicate()
	__allocate_point_saved = false
	sync_allocated_to_base()

func get_bonus_stat() -> Dictionary:
	return bonus_stats

func set_bonus_stats(new_bonus: Dictionary) -> void:
	bonus_stats = new_bonus.duplicate()

func sync_allocated_to_base() -> void:
	set_str(__allocated_stats["STR"])
	set_rec(__allocated_stats["REC"])
	set_int(__allocated_stats["INT"])
	set_wis(__allocated_stats["WIS"])
	set_dex(__allocated_stats["DEX"])
	set_luc(__allocated_stats["LUC"])

## Returns a copy of the allocated stats dictionary.
func get_stat_alloc() -> Dictionary:
	return __allocated_stats.duplicate()

# ─── Computed Stats ──────────────────────────────────────────────────────────
func update_current_health_and_mana():
	__base_stats["HP"] = get_max_hp()
	__base_stats["MP"] = get_max_mp()

func get_base_stats() -> Dictionary:
	return {
		"STR": get_base_stat("STR"),
		"REC": get_base_stat("REC"),
		"INT": get_base_stat("INT"),
		"WIS": get_base_stat("WIS"),
		"DEX": get_base_stat("DEX"),
		"LUC": get_base_stat("LUC"),
		"HP": get_max_hp(),
		"MP": get_max_mp(),
	}

func get_base_stats_value(key: String) -> int:
	if __base_stats.keys().has(key):
		return __base_stats[key]
	printerr("The key " + key + " not found in the __base_stats dictionary")
	return 0

func get_stats_bonus() -> Dictionary:
	return __bonus_stats

func get_base_stat(key: String) -> int:
	return __base_stats.get(key, 0)

func add_stat_bonus(stat: String, value: int) -> void:
	if __bonus_stats.has(stat):
		__bonus_stats[stat] = max(0, __bonus_stats[stat] + value)

func remove_stat_bonus(stat: String, value: int) -> void:
	if __bonus_stats.has(stat):
		__bonus_stats[stat] = max(0, __bonus_stats[stat] - value)

func add_stat_bonuses(bonuses: Dictionary) -> void:
	for stat in bonuses:
		add_stat_bonus(stat, int(bonuses[stat]))

func remove_stat_bonuses(bonuses: Dictionary) -> void:
	for stat in bonuses:
		remove_stat_bonus(stat, int(bonuses[stat]))

## Returns a dictionary of primary stats with totals (base + bonus).
func get_primary_stats_breakdown() -> Dictionary:
	return {
		"STR": get_total("STR"),
		"REC": get_total("REC"),
		"INT": get_total("INT"),
		"WIS": get_total("WIS"),
		"DEX": get_total("DEX"),
		"LUC": get_total("LUC")
	}

## Returns a dictionary of all derived secondary combat stats.
func get_secondary_stats_breakdown() -> Dictionary:
	return {
		"max_hp": get_max_hp(),
		"max_mp": get_max_mp(),
		"def": get_def(),
		"resist": get_resist(),
		"melee_atk": get_melee_atk(),
		"ranged_atk": get_ranged_atk(),
		"magic_atk": get_magic_atk(),
		"crit_chance": get_crit_chance(),
		"crit_damage": get_crit_damage()
	}

func get_stats_bonus_value(stat: String) -> int:
	return __bonus_stats.get(stat, 0)

func get_base_weapon_power() -> float:
	return get_total("weapon_power")

func get_base_armor_defense() -> float:
	return get_total("armor_defense")

func get_base_armor_resist() -> float:
	return get_total("armor_resist")

## Calculates maximum health points.
func get_max_hp() -> float:
	var base_hp = 100.0
	var hp_bonus = (get_total("REC")) * 5.0
	var max_hp_bonus = get_bonus_max_hp()
	var passive_hp = __passive_stats.get("MP", 0)
	var buff_hp = __buff_stats.get("MP", 0)
	return base_hp + hp_bonus + max_hp_bonus + passive_hp + buff_hp

## Calculates maximum mana points.
func get_max_mp() -> float:
	var base_mp = 50.0
	var mp_bonus = (get_total("WIS")) * 5.0
	var max_mp_bonus = get_bonus_max_mp()
	var passive_mp = __passive_stats.get("MP", 0)
	var buff_mp = __buff_stats.get("MP", 0)
	return base_mp + mp_bonus + max_mp_bonus + passive_mp + buff_mp

func get_current_hp() -> float:
	return __base_stats["HP"]

func get_current_mp() -> float:
	return __base_stats["MP"]

func set_current_hp(current_hp: float):
	if current_hp >= 0 and current_hp <= get_max_hp():
		__base_stats["HP"] = current_hp

func set_current_mp(current_mp: float):
	if current_mp >= 0 and current_mp <= get_max_mp():
		__base_stats["MP"] = current_mp

## Calculates physical defense.
func get_def() -> float:
	return __base_stats["REC"] + get_bonus_armor_defense()

## Calculates magical resistance.
func get_resist() -> float:
	return __base_stats["WIS"] + get_bonus_armor_resist()

## Calculates melee attack power.
func get_melee_atk() -> float:
	return floor(get_total("STR") * 1.3) + floor(get_total("DEX") * 0.25) + get_total("weapon_power")

## Calculates ranged attack power.
func get_ranged_atk() -> float:
	return floor(get_total("STR") * 1.3) + floor(get_total("LUC") * 0.3) + floor(get_total("DEX") * 0.2) + get_total("weapon_power")

## Calculates magic attack power.
func get_magic_atk() -> float:
	return floor(get_total("INT") * 1.3) + floor(get_total("WIS") * 0.2) + get_total("weapon_power")

## Calculates critical hit chance percentage.
func get_crit_chance() -> float:
	return floor(get_total("LUC") * 0.2) # percent

## Calculates critical hit damage multiplier.
func get_crit_damage() -> float:
	return 1.5 + floor(get_total("LUC") * 0.0075) # multiplier

func set_str(new_str: int) -> void:
	__base_stats['STR'] = new_str

func set_rec(new_rec: int) -> void:
	__base_stats['REC'] = new_rec

func set_int(new_int: int) -> void:
	__base_stats['INT'] = new_int

func set_wis(new_wis: int) -> void:
	__base_stats['WIS'] = new_wis

func set_dex(new_dex: int) -> void:
	__base_stats['DEX'] = new_dex

func set_luc(new_luc: int) -> void:
	__base_stats['LUC'] = new_luc

## Calculates bonus maximum health points.
func get_bonus_max_hp() -> float:
	return get_stats_bonus_value("max_health")

## Calculates bonus maximum mana points.
func get_bonus_max_mp() -> float:
	return get_stats_bonus_value("max_mana")

## Calculates bonus strength.
func get_bonus_str() -> int:
	return get_stats_bonus_value("STR")

## Calculates bonus recupration.
func get_bonus_rec() -> int:
	return get_stats_bonus_value("REC")

## Calculates bonus intelligence.
func get_bonus_int() -> int:
	return get_stats_bonus_value("INT")

## Calculates bonus wisdom.
func get_bonus_wis() -> int:
	return get_stats_bonus_value("WIS")

## Calculates bonus dexterity.
func get_bonus_dex() -> int:
	return get_stats_bonus_value("DEX")

## Calculates bonus luck.
func get_bonus_luc() -> int:
	return get_stats_bonus_value("LUC")


## Calculates bonus weapon power.
func get_bonus_weapon_power() -> float:
	return get_stats_bonus_value("weapon_power")

## Calculates bonus armor defense.
func get_bonus_armor_defense() -> float:
	return get_stats_bonus_value("armor_defense")

## Calculates bonus armor resistance.
func get_bonus_armor_resist() -> float:
	return get_stats_bonus_value("armor_resist")

func get_total(key: String) -> int:
	return get_base_stats_value(key) + get_stats_bonus_value(key)

## Converts base stats to a dictionary format.
func to_dict() -> Dictionary:
	return {
		"max_health": get_max_hp(),
		"max_mana": get_max_mp(),
		"STR": get_base_stat("STR"),
		"REC": get_base_stat("REC"),
		"INT": get_base_stat("INT"),
		"WIS": get_base_stat("WIS"),
		"DEX": get_base_stat("DEX"),
		"LUC": get_base_stat("LUC")
	}