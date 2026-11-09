extends Skill
class_name BuffSkill

# Buffs
enum BuffType {
	# Offensive Buffs
	attack_power,
	critical_damage,
	attack_speed,
	casting_speed,
	# Defensive & Survival Buffs
	physical_defence,
	magical_resistance,
	max_hp,
	max_mp,
	regeneration,
	absorption,
	# Utility & Movement Buffs
	movement_speed,
	accuracy,
	evasion,
	none
}

@export var buff_type: BuffType
@export var value: Array[float]
@export var duration: float
@export var is_percentage: bool

func get_value() -> float:
	var idx = clampi(level - 1, 0, value.size() - 1)
	return value[idx] if not value.is_empty() else 0.0