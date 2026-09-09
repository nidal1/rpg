extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
## List of available stat names.
const STAT_NAMES = ["HP", "MP", "STR", "REC", "INT", "WIS", "DEX", "LUC"]
## List of available stat names without HP and MP.
const STAT_NAMES_NO_FLT = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]
## Number of stat points awarded per level up.
const POINTS_STATS_PER_LEVEL = 5


# Primary base stats
var __stats: CharacterStats = null

# ─── Private Variables ───────────────────────────────────────────────────────
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
	__stats = cs.duplicate()
	__allocated_stats = __stats.get_allocated_stats()
	__temp_allocated_stats = __allocated_stats.duplicate()
	bonus_stats = __stats.get_stats_bonus_dict()

	__stats.update_current_health_and_mana()

func get_stats() -> CharacterStats:
	return __stats

func get_base_stat(key: String) -> int:
	return __stats.get_base_stats_value(key)

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
	if __stats:
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
	if __stats:
		sync_allocated_to_base()
	set_stat_points_available(get_stat_points_available() + 1)
	return true

## Saves the currently allocated stats.
func save_stats() -> void:
	if __stat_points_available <= 0:
		__allocate_point_saved = true
	
	__temp_stat_points_available = __stat_points_available
	__temp_allocated_stats = __allocated_stats.duplicate()
	if __stats:
		sync_allocated_to_base()

## Cancels the current stat allocation and reverts to the last saved state.
func cancel_stats() -> void:
	__stat_points_available = __temp_stat_points_available
	__allocated_stats = __temp_allocated_stats.duplicate()
	__allocate_point_saved = false
	if __stats:
		sync_allocated_to_base()

func get_bonus_stat() -> Dictionary:
	return bonus_stats

func set_bonus_stats(new_bonus: Dictionary) -> void:
	bonus_stats = new_bonus.duplicate()

func sync_allocated_to_base() -> void:
	__stats.from_dict_to_base_stats(__allocated_stats)

## Returns a copy of the allocated stats dictionary.
func get_stat_alloc() -> Dictionary:
	return __allocated_stats.duplicate()



# ─── Computed Stats ──────────────────────────────────────────────────────────
## Gets the total value of a stat including base and allocated points.
func get_total(_stat_name: String) -> int:
	if __stats:
		return __stats.get_total(_stat_name)
	return __allocated_stats.get(_stat_name, 0)


func get_base_weapon_power() -> float:
	return __stats.get_total("weapon_power")

func get_base_armor_defense() -> float:
	return __stats.get_total("armor_defense")

func get_base_armor_resist() -> float:
	return __stats.get_total("armor_resist")

func set_base_weapon_power(power: float) -> void:
	__stats.weapon_power = power

func set_base_armor_defense(value: float) -> void:
	__stats.armor_defense = value

func set_base_armor_resist(resist: float) -> void:
	__stats.armor_resist = resist