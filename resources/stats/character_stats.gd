extends Resource
class_name CharacterStats

# ─── Base Stats ──────────────────────────────────────
var max_health: float = 0.0
var max_mana: float = 0.0

@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var DEX: int = 0
@export var WIS: int = 0
@export var LUC: int = 0

# ─── Weapon Power (set by equipment later) ───────────
var weapon_power: float = 0.0
var armor_defense: float = 0.0
var armor_resist: float = 0.0

var __bonus_stats: Dictionary = {
	"max_health": 0,
	"max_mana": 0,
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0,
	"weapon_power": 0,
	"armor_defense": 0,
	"armor_resist": 0
}

## Returns a copy of the stats.
func get_instance() -> CharacterStats:
	if not is_instance_valid(self):
		return null
	var instance: CharacterStats = duplicate()
	instance.set_max_hp(get_max_hp())
	instance.set_max_mp(get_max_mp())
	return instance

func get_base_stats_value(key: String) -> int:
	match key:
		"max_health": return round(get_max_hp())
		"max_mana": return round(get_max_mp())
		"STR": return STR
		"REC": return REC
		"INT": return INT
		"WIS": return WIS
		"DEX": return DEX
		"LUC": return LUC
		"weapon_power": return round(weapon_power)
		"armor_defense": return round(armor_defense)
		"armor_resist": return round(armor_resist)
		_: return 0


## Returns the allocated stats.
func get_allocated_stats() -> Dictionary:
	return {
		"STR": STR,
		"REC": REC,
		"INT": INT,
		"WIS": WIS,
		"DEX": DEX,
		"LUC": LUC
	}

## Calculates maximum health points.
func get_max_hp() -> float:
	return 100.0 + (REC * 5.0) + get_bonus_max_hp()

## Calculates maximum mana points.
func get_max_mp() -> float:
	return 50.0 + (WIS * 5.0) + get_bonus_max_mp()

## Calculates physical defense.
func get_def() -> float:
	return REC + armor_defense + get_bonus_armor_defense()

## Calculates magical resistance.
func get_resist() -> float:
	return WIS + armor_resist + get_bonus_armor_resist()

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


## Calculates weapon power.
func get_weapon_power() -> float:
	return weapon_power

## Calculates armor defense.
func get_armor_defense() -> float:
	return armor_defense

## Calculates armor resistance.
func get_armor_resist() -> float:
	return armor_resist

func set_max_hp(new_max_hp: float) -> void:
	max_health = new_max_hp

func set_max_mp(new_max_mp: float) -> void:
	max_mana = new_max_mp

func set_str(new_str: int) -> void:
	STR = new_str

func set_rec(new_rec: int) -> void:
	REC = new_rec

func set_int(new_int: int) -> void:
	INT = new_int

func set_wis(new_wis: int) -> void:
	WIS = new_wis

func set_dex(new_dex: int) -> void:
	DEX = new_dex

func set_luc(new_luc: int) -> void:
	LUC = new_luc

func set_weapon_power(new_weapon_power: float) -> void:
	weapon_power = new_weapon_power

func set_armor_defense(new_armor_defense: float) -> void:
	armor_defense = new_armor_defense

func set_armor_resist(new_armor_resist: float) -> void:
	armor_resist = new_armor_resist

## Converts base stats to a dictionary format.
func to_dict() -> Dictionary:
	return {
		"max_health": get_max_hp(),
		"max_mana": get_max_mp(),
		"STR": STR,
		"REC": REC,
		"INT": INT,
		"WIS": WIS,
		"DEX": DEX,
		"LUC": LUC,
		"weapon_power": weapon_power,
		"armor_defense": armor_defense,
		"armor_resist": armor_resist,
	}

func from_dict_to_base_stats(stats: Dictionary) -> void:
	set_max_hp(stats["max_health"])
	set_max_mp(stats["max_mana"])
	set_str(stats["STR"])
	set_rec(stats["REC"])
	set_int(stats["INT"])
	set_wis(stats["WIS"])
	set_dex(stats["DEX"])
	set_luc(stats["LUC"])
	set_weapon_power(stats["weapon_power"])
	set_armor_defense(stats["armor_defense"])
	set_armor_resist(stats["armor_resist"])

func get_stats_bonus_dict() -> Dictionary:
	return __bonus_stats

func get_stats_bonus_value(stat: String) -> int:
	return __bonus_stats[stat]

func add_stat_bonus(stat: String, value: int) -> void:
	__bonus_stats[stat] = max(0, __bonus_stats[stat] + value)

func remove_stat_bonus(stat: String, value: int) -> void:
	__bonus_stats[stat] = max(0, __bonus_stats[stat] - value)


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
