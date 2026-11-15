extends Skill
class_name PassiveSkill

enum PassiveStatType {
	max_hp,
	max_mp,
	attack_damage,
	movement_speed,
	physical_defence,
	magical_resistance,
	critical_damage
}

@export var stat_type: PassiveStatType
@export var bonus_value: Array[float] 
@export var is_percentage: bool

func get_value() -> Dictionary:
	var idx = clampi(level - 1, 0, bonus_value.size() - 1)
	return {
		"value": bonus_value[idx] if not bonus_value.is_empty() else 0.0,
		"stat_type": PassiveStatType.keys()[stat_type],
		"is_percentage_value": is_percentage
	}