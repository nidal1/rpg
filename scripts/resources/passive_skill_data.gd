extends Skill
class_name PassiveSkill

enum PassiveStatType {
	max_hp,
	max_mp,
	attack_power,
	physical_defence,
	magical_resistance,
	movement_speed,
	critical_damage
}

@export var stat_type: PassiveStatType
@export var bonus_value: float 
@export var is_percentage: bool