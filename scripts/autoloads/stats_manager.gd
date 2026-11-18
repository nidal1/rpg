extends Node
class_name StatsManager

const STAT_NAMES_NO_FLT: Array[String] = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]
const POINTS_PER_LEVEL: int = 5

func initialize(_character: Character) -> void:
	StatsData.initialize_character_stats(_character)
	EventBus.stats_updated.emit()
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())
	EventBus.buff_skill_duration_ended.connect(_on_buff_skill_duration_ended)
	EventBus.skill_slot_clicked.connect(_on_skill_slot_clicked)

func add_stat_point(stat_name: String) -> bool:
	if StatsData.add_stat_point(stat_name):
		EventBus.stats_updated.emit()
		EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())
		return true
	return false

func sub_stat_point(stat_name: String) -> bool:
	if StatsData.sub_stat_point(stat_name):
		EventBus.stats_updated.emit()
		EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())
		return true
	return false

func save_stats() -> void:
	StatsData.save_stats()
	EventBus.stats_updated.emit()
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())

func cancel_stats() -> void:
	StatsData.cancel_stats()
	EventBus.stats_updated.emit()
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())

func update_available_points_on_level_up() -> void:
	StatsData.set_stat_points_available(StatsData.get_stat_points_available() + POINTS_PER_LEVEL)
	StatsData.set_stat_temp_points_available(StatsData.get_stat_points_available())
	StatsData.set_allocate_point_saved(false)
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())
	EventBus.stats_updated.emit()

## Calculate equipment stats bonus 
## args { equipement: EquipableItem, operation: "equip" or "unequip"}
func calculate_equipment_bonus(equipement: EquipableItem, operation: String = "equip"):
	if is_instance_valid(equipement):
		if equipement.base_damage > 0:
			if operation == "equip":
				StatsData.add_stat_bonus("weapon_power", equipement.base_damage)
			elif operation == "unequip":
				StatsData.remove_stat_bonus("weapon_power", equipement.base_damage)
				
		if equipement.base_defense > 0:
			if operation == "equip":
				StatsData.add_stat_bonus("armor_defense", equipement.base_defense)
			elif operation == "unequip":
				StatsData.remove_stat_bonus("armor_defense", equipement.base_defense)

func get_total(stat_name: String) -> int:
	return StatsData.get_total(stat_name) if StatsData else 0

func get_allocated_stat(stat_name: String) -> int:
	return StatsData.get_allocated_stat(stat_name) if StatsData else 0

func get_temp_allocated_stat(stat_name: String) -> int:
	return StatsData.get_temp_allocated_stat(stat_name) if StatsData else 0

func calculate_passive_skills_stats(_skill: Skill):
	
	StatsData.set_passive_stat(_skill)
	StatsData.secondary_stats = StatsData.get_secondary_stats_breakdown()
	
	EventBus.stats_updated.emit()

func _on_buff_skill_duration_ended(_skill: BuffSkill, _value: float):
	var key = _skill.get_value()["stat_type"]
	StatsData.remove_buff_stat(key, _value)
	StatsData.secondary_stats = StatsData.get_secondary_stats_breakdown()
	
	EventBus.stats_updated.emit()

func _on_skill_slot_clicked(_skill: Skill):
	if _skill is BuffSkill:
		var val = StatsData.set_buff_stat(_skill)
		EventBus.buff_skill_duration_started.emit(_skill, val)
		EventBus.add_active_effect_to_effectsbar.emit(_skill)
		StatsData.secondary_stats = StatsData.get_secondary_stats_breakdown()
		EventBus.stats_updated.emit()
