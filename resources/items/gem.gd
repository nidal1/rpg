class_name Gem
extends Item

enum GemType {RUBY, SAPPHIRE, EMERALD, TOPAZ, AMETHYST, DIAMOND}

@export var gem_type: GemType
@export var gem_level: int = 1 # 1-3

# bonuses per level [lv1, lv2, lv3]
@export var DEX: Array[float] = []
@export var STR: Array[float] = []
@export var LUC: Array[float] = []
@export var INT: Array[float] = []
@export var WIS: Array[float] = []
@export var REC: Array[float] = []

func get_dex_bonus() -> float:
	if DEX.size() == 0:
		return 0.0
	return DEX[gem_level - 1]

func get_str_bonus() -> float:
	if STR.size() == 0:
		return 0.0
	return STR[gem_level - 1]

func get_luc_bonus() -> float:
	if LUC.size() == 0:
		return 0.0
	return LUC[gem_level - 1]

func get_int_bonus() -> float:
	if INT.size() == 0:
		return 0.0
	return INT[gem_level - 1]

func get_wis_bonus() -> float:
	if WIS.size() == 0:
		return 0.0
	return WIS[gem_level - 1]

func get_rec_bonus() -> float:
	if REC.size() == 0:
		return 0.0
	return REC[gem_level - 1]
