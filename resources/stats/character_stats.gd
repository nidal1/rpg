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

## Returns a copy of the stats.
func get_instance() -> CharacterStats:
	if not is_instance_valid(self):
		return null
	var instance: CharacterStats = duplicate()
	instance.set_max_hp(get_max_hp())
	instance.set_max_mp(get_max_mp())
	return instance

## Calculates maximum health points.
func get_max_hp() -> float:
	return 100.0 + (REC * 5.0)

## Calculates maximum mana points.
func get_max_mp() -> float:
	return 50.0 + (WIS * 5.0)

## Calculates critical hit chance percentage.
func get_crit_chance() -> float:
	return LUC * 0.2 # percent

## Calculates critical hit damage multiplier.
func get_crit_damage() -> float:
	return 1.5 + (LUC * 0.0075) # multiplier

## Calculates physical defense.
func get_def() -> float:
	return REC + armor_defense

## Calculates magical resistance.
func get_resist() -> float:
	return WIS + armor_resist

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
func from_base_stats_to_dict() -> Dictionary:
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
