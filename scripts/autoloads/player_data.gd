extends Node

const STAT_NAMES = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]
const POINTS_STATS_PER_LEVEL = 5
var allocate_point_saved = false


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

var __temp_allocated_stats: Dictionary = {
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0
}


var __current_drop_table: Array[Item] = []

# ─── Setup ───────────────────────────────────────────
func initialize(cls: CharacterClass) -> void:
	__base_stats = cls.base_stats.duplicate()
	__allocated_stats = from_base_stats_to_dict()
	__temp_allocated_stats = from_base_stats_to_dict()

# ─── XP & Leveling ───────────────────────────────────
func set_player_level(new_level: int) -> void:
	__player_level = new_level

func get_player_level() -> int:
	return __player_level

func set_current_xp(new_xp: int) -> void:
	__current_xp = new_xp

func get_current_xp() -> int:
	return __current_xp

func set_total_xp_to_next_level(new_xp: int) -> void:
	__total_xp_to_next_level = new_xp

func get_total_xp_to_next_level() -> int:
	return __total_xp_to_next_level


# ─── Stat Allocation ─────────────────────────────────
func set_stat_points_available(new_points: int) -> void:
	__stat_points_available = new_points

func get_stat_points_available() -> int:
	return __stat_points_available

func set_allocated_stat(stat_name: String, stat_value: int) -> void:
	__allocated_stats[stat_name] = stat_value

func get_allocated_stat(stat_name: String) -> int:
	return __allocated_stats[stat_name]

func get_stat_alloc() -> Dictionary:
	return __allocated_stats.duplicate()

func get_total(_stat_name: String) -> int:
	var base_value: int = 0
	match _stat_name:
		"STR": base_value = __base_stats.strength
		"REC": base_value = __base_stats.recovery
		"INT": base_value = __base_stats.intelligence
		"WIS": base_value = __base_stats.wisdom
		"DEX": base_value = __base_stats.dexterity
		"LUC": base_value = __base_stats.luck
	return base_value + __allocated_stats.get(_stat_name, 0)

func update_available_points():
	set_stat_points_available(get_stat_points_available() + POINTS_STATS_PER_LEVEL)
	__temp_stat_points_available = __stat_points_available

func add_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() <= 0 or allocate_point_saved or _stat_name not in STAT_NAMES:
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) + 1)
	set_stat_points_available(get_stat_points_available() - 1)
	return true

func sub_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() >= __temp_stat_points_available or allocate_point_saved or _stat_name not in STAT_NAMES:
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) - 1)
	set_stat_points_available(get_stat_points_available() + 1)
	return true


func save_stats():
	if __stat_points_available <= 0:
		allocate_point_saved = true
	
	__temp_stat_points_available = __stat_points_available
	__temp_allocated_stats = __allocated_stats.duplicate()
	

func cancel_stats():
	__stat_points_available = __temp_stat_points_available
	__allocated_stats = __temp_allocated_stats.duplicate()
	allocate_point_saved = false

# ─── Computed Stats ───────────────────────────────────
func get_melee_atk() -> float:
	return floor(get_total("STR") * 1.3) + floor(get_total("DEX") * 0.25) + __base_stats.weapon_power

func get_ranged_atk() -> float:
	return get_total("STR") + (get_total("LUC") * 0.3) + (get_total("DEX") * 0.2) + __base_stats.weapon_power

func get_magic_atk() -> float:
	return floor(get_total("INT") * 1.3) + floor(get_total("WIS") * 0.2) + __base_stats.weapon_power

func get_max_hp() -> float:
	return 100.0 + (get_total("REC") * 5.0)

func get_max_mp() -> float:
	return 50.0 + (get_total("WIS") * 5.0)

func get_def() -> float:
	return get_total("REC") + __base_stats.armor_value

func get_resist() -> float:
	return get_total("WIS") + __base_stats.armor_resist

func get_crit_chance() -> float:
	return get_total("LUC") * 0.2 # percent

func get_crit_damage() -> float:
	return 1.5 + (get_total("LUC") * 0.0075) # multiplier

func from_base_stats_to_dict() -> Dictionary:
	return {
		"STR": __base_stats.STR,
		"REC": __base_stats.REC,
		"INT": __base_stats.INT,
		"WIS": __base_stats.WIS,
		"DEX": __base_stats.DEX,
		"LUC": __base_stats.LUC,
		"weapon_power": __base_stats.weapon_power,
		"armor_value": __base_stats.armor_value,
		"armor_resist": __base_stats.armor_resist,
	}


# ─── Drop items ───────────────────────────────────

func add_drop_item(item: Item) -> void:
	__current_drop_table.append(item)

func remove_drop_item(item: Item) -> void:
	__current_drop_table.erase(item)
