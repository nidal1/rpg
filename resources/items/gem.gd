class_name Gem
extends Item

enum GemType {RUBY, SAPPHIRE, EMERALD, TOPAZ, AMETHYST, DIAMOND}

@export var gem_type: GemType
@export var gem_level: int = 1 # 1-3

# bonuses per level [lv1, lv2, lv3]
@export var atk_bonus: Array[float] = []
@export var def_bonus: Array[float] = []
@export var hp_bonus: Array[float] = []
@export var mp_bonus: Array[float] = []
@export var crit_bonus: Array[float] = []

func get_atk_bonus() -> float:
	return atk_bonus[gem_level - 1]

func get_def_bonus() -> float:
	return def_bonus[gem_level - 1]

func get_hp_bonus() -> float:
	return hp_bonus[gem_level - 1]

func get_mp_bonus() -> float:
	return mp_bonus[gem_level - 1]

func get_crit_bonus() -> float:
	return crit_bonus[gem_level - 1]
