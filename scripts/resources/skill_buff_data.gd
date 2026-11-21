extends Skill
class_name BuffSkill

# Buffs
enum BuffType {
	# Offensive Buffs
	attack_damage,
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

func can_cast_skill() -> bool:
	# TODO: 
	# هنا كتأكد من الشروط كاملة:
	# 1. واش المانا كافية؟ (مثلا مقارنة مع StatsData.get_current_mp())
	# 2. واش السكيل في فترة التبريد (Cooldown)؟
	# 3. واش الشخيصية قادرة تتحرك (مش فـ Stun مثلاً)؟
	# FIXME: khesni ndir variable khas b current mp and hp o man3tamedch 3la base stats
	var player_has_enough_mp = StatsData.get_base_stat("MP") >= mp_cost
	if player_has_enough_mp : return true
	return false

func get_value() -> Dictionary:
	var idx = clampi(level - 1, 0, value.size() - 1)
	return {
		"value": value[idx] if not value.is_empty() else 0.0,
		"stat_type": BuffType.keys()[buff_type],
		"is_percentage_value": is_percentage
	}