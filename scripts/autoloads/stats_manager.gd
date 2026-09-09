extends Node
class_name StatsManager

const STAT_NAMES_NO_FLT: Array[String] = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]
const POINTS_PER_LEVEL: int = 5


func initialize(character_stats: CharacterStats) -> void:
	StatsData.initialize_from_character_stats(character_stats)
	EventBus.stats_updated.emit(StatsData)
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())

func add_stat_point(stat_name: String) -> bool:
	if StatsData.add_stat_point(stat_name):
		EventBus.stats_updated.emit(StatsData)
		EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())
		return true
	return false

func sub_stat_point(stat_name: String) -> bool:
	if StatsData.sub_stat_point(stat_name):
		EventBus.stats_updated.emit(StatsData)
		EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())
		return true
	return false

func save_stats() -> void:
	StatsData.save_stats()
	EventBus.stats_updated.emit(StatsData)
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())

func cancel_stats() -> void:
	StatsData.cancel_stats()
	EventBus.stats_updated.emit(StatsData)
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())

func update_available_points_on_level_up() -> void:
	StatsData.set_stat_points_available( StatsData.get_stat_points_available() + POINTS_PER_LEVEL)
	StatsData.set_stat_temp_points_available( StatsData.get_stat_points_available())
	StatsData.set_allocate_point_saved(false)
	EventBus.stat_points_available_changed.emit(StatsData.get_stat_points_available())
	EventBus.stats_updated.emit(StatsData)

## Calculate equipement stats bonus 
## args { equipement: Equipable, operation: "equip" or "unequip"}
func calculate_equipment_bonus(equipement: Equipable, operation: String = "equip"):
	if is_instance_valid(equipement):
		var effective_stats_breakdown = equipement.get_effective_stats_breakdown()

		for s in effective_stats_breakdown:
			var base = effective_stats_breakdown[s]["base"]
			var gem = effective_stats_breakdown[s]["gem"]
			
			if operation == "equip":
				StatsData.get_stats().add_stat_bonus(s, base + gem)
			elif operation == "unequip":
				StatsData.get_stats().remove_stat_bonus(s, base + gem)

		if equipement is Weapon:
			if operation == "equip":
				StatsData.get_stats().add_stat_bonus("weapon_power", equipement.base_attack_power)
			if operation == "unequip":
				StatsData.get_stats().remove_stat_bonus("weapon_power", equipement.base_attack_power)
			return
		
		if equipement is Armor:
			if operation == "equip":
				StatsData.get_stats().add_stat_bonus("armor_defense", equipement.base_defense)
				StatsData.get_stats().add_stat_bonus("armor_resist", equipement.base_resist)
			if operation == "unequip":
				StatsData.get_stats().remove_stat_bonus("armor_defense", equipement.base_defense)
				StatsData.get_stats().remove_stat_bonus("armor_resist", equipement.base_resist)
			return
		

func get_total(stat_name: String) -> int:
	return StatsData.get_total(stat_name) if StatsData else 0

func get_allocated_stat(stat_name: String) -> int:
	return StatsData.get_allocated_stat(stat_name) if StatsData else 0

func get_temp_allocated_stat(stat_name: String) -> int:
	return StatsData.get_temp_allocated_stat(stat_name) if StatsData else 0
