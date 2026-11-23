extends Timer
class_name RegenrationBuffSkill

@export var skill: BuffSkill

var total_seconds: int = 0

func _on_timeout() -> void:
	total_seconds += 1
	if total_seconds == skill.duration:
		queue_free()
	
	if skill.buff_type == BuffSkill.BuffType.hp_regeneration:
		var current_hp = StatsData.get_current_hp()
		var max_hp = StatsData.get_max_hp()
		current_hp += skill.get_value()["value"]

		StatsData.set_current_hp(min(current_hp, max_hp))
		EventBus.stats_updated.emit()
	elif skill.buff_type == BuffSkill.BuffType.mp_regeneration:
		var current_mp = StatsData.get_current_mp()
		var max_mp = StatsData.get_max_mp()
		current_mp += skill.get_value()["value"]
		
		StatsData.set_current_mp(min(current_mp, max_mp))
		EventBus.stats_updated.emit()

	