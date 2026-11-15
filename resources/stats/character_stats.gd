extends Resource
class_name CharacterStats

# ─── Base Stats ──────────────────────────────────────
@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var WIS: int = 0
@export var DEX: int = 0
@export var LUC: int = 0

@export var HP: float = 0.0
@export var MP: float = 0.0

@export var movement_speed: float = 300.0
@export var attack_range: float = 300.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0

# ─── Bonus stats (set by equipment or gems) ───────────
@export var __bonus_stats: Dictionary = {
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
	"armor_resist": 0.0,
	"attack_damage": 0.0,
	"attack_speed": 0.0,
	"attack_range": 0.0,
	"movement_speed": 0.0
}

## Returns a copy of the stats.
func get_instance() -> CharacterStats:
	if not is_instance_valid(self):
		return null
	var instance: CharacterStats = duplicate()
	return instance

func get_base_stats() -> Dictionary:
	return {
		"HP": HP,
		"MP": MP,
		"STR": STR,
		"REC": REC,
		"INT": INT,
		"WIS": WIS,
		"DEX": DEX,
		"LUC": LUC,
		"weapon_power": 0.0,
		"armor_defense": 0.0,
		"armor_resist": 0.0,
		"attack_damage": attack_damage,
		"attack_speed": attack_speed,
		"attack_range": attack_range,
		"movement_speed": movement_speed
	}

func get_stats_bonus_dict() -> Dictionary:
	return __bonus_stats