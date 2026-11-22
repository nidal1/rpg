extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
## List of available stat names.
const STAT_NAMES = ["HP", "MP", "STR", "REC", "INT", "WIS", "DEX", "LUC"]
## List of available stat names without HP and MP.
const STAT_NAMES_NO_FLT = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]
## Number of stat points awarded per level up.
const POINTS_STATS_PER_LEVEL = 5


# ─── Private Variables ───────────────────────────────────────────────────────
var __base_stats: Dictionary = {
	"HP": 0.0,
	"MP": 0.0,
	"STR": 0.0,
	"REC": 0.0,
	"INT": 0.0,
	"WIS": 0.0,
	"DEX": 0.0,
	"LUC": 0.0,
	"weapon_power": 0.0,
	"armor_defense": 0.0,
	"armor_resist": 0.0,
	"attack_damage": 0.0,
	"attack_speed": 0.0,
	"attack_range": 0.0,
	"movement_speed": 0.0,
	"cast_speed": 0.0
}

var __bonus_stats: Dictionary = {
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

var __passive_stats: Dictionary = {
	"max_hp": 0.0,
	"max_mp": 0.0,
	"attack_damage": 0.0,
	"attack_speed": 0.0,
	"movement_speed": 0.0,
	"physical_defence": 0.0,
	"magical_resistance": 0.0,
	"critical_damage": 0.0
}

var __buff_stats: Dictionary = {
	"max_hp": 0.0,
	"max_mp": 0.0,
	"STR": 0.0,
	"REC": 0.0,
	"INT": 0.0,
	"WIS": 0.0,
	"DEX": 0.0,
	"LUC": 0.0,
	"attack_damage": 0.0,
	"attack_speed": 0.0,
	"attack_range": 0.0,
	"movement_speed": 0.0,
	"physical_defence": 0.0,
	"magical_resistance": 0.0,
	"critical_chance": 0.0,
	"critical_damage": 0.0,
	"absorption": 0.0,
	"cast_speed": 0.0
}

var __stat_points_available: int = 0
var __temp_stat_points_available: int = 0
var __allocate_point_saved: bool = false
var __allocated_stats: Dictionary = {
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0
}
var __temp_allocated_stats: Dictionary = {}
var bonus_stats: Dictionary = {}

var secondary_stats

func initialize_character_stats(_character: Character) -> void:
	var cc: CharacterClass = _character.character_class
	if not cc: return
	__base_stats = cc.get_class_stats().get_base_stats()
	__bonus_stats = cc.get_class_stats().get_stats_bonus_dict()
	__allocated_stats = __base_stats.duplicate()
	__temp_allocated_stats = __allocated_stats.duplicate()

	_character.speed = get_movement_speed()
	_character.attack_range = get_attack_range()

	secondary_stats = get_secondary_stats_breakdown()


	update_current_health_and_mana()

func get_allocated_stat(key: String) -> int:
	return __allocated_stats.get(key, get_base_stat(key))

## Sets the allocated value for a specific stat.
func set_allocated_stat(stat_name: String, stat_value: int) -> void:
	__allocated_stats[stat_name] = stat_value

func get_temp_allocated_stat(key: String) -> int:
	return __temp_allocated_stats.get(key, get_base_stat(key))

## Gets the number of available stat points.
func get_stat_points_available() -> int:
	return __stat_points_available

## Sets the number of available stat points.
func set_stat_points_available(new_points: int) -> void:
	__stat_points_available = new_points

## Gets the number of available stat points.
func get_stat_temp_points_available() -> int:
	return __temp_stat_points_available

## Sets the number of available stat points.
func set_stat_temp_points_available(new_points: int) -> void:
	__temp_stat_points_available = new_points

func get_allocate_point_saved() -> bool:
	return __allocate_point_saved

func set_allocate_point_saved(saved: bool) -> void:
	__allocate_point_saved = saved

## Adds a stat point to the specified stat.
func add_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() <= 0 or _stat_name not in STAT_NAMES_NO_FLT:
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) + 1)
	sync_allocated_to_base()
	set_stat_points_available(get_stat_points_available() - 1)
	return true

## Subtracts a stat point from the specified stat.
func sub_stat_point(_stat_name: String) -> bool:
	if get_stat_points_available() >= __temp_stat_points_available or _stat_name not in STAT_NAMES_NO_FLT:
		return false
	if get_allocated_stat(_stat_name) <= get_temp_allocated_stat(_stat_name):
		return false
	set_allocated_stat(_stat_name, get_allocated_stat(_stat_name) - 1)
	sync_allocated_to_base()
	set_stat_points_available(get_stat_points_available() + 1)
	return true

## Saves the currently allocated stats.
func save_stats() -> void:
	if __stat_points_available <= 0:
		__allocate_point_saved = true
	
	__temp_stat_points_available = __stat_points_available
	__temp_allocated_stats = __allocated_stats.duplicate()
	sync_allocated_to_base()

## Cancels the current stat allocation and reverts to the last saved state.
func cancel_stats() -> void:
	__stat_points_available = __temp_stat_points_available
	__allocated_stats = __temp_allocated_stats.duplicate()
	__allocate_point_saved = false
	sync_allocated_to_base()

func get_bonus_stat() -> Dictionary:
	return bonus_stats

func set_bonus_stats(new_bonus: Dictionary) -> void:
	bonus_stats = new_bonus.duplicate()

func sync_allocated_to_base() -> void:
	set_str(__allocated_stats["STR"])
	set_rec(__allocated_stats["REC"])
	set_int(__allocated_stats["INT"])
	set_wis(__allocated_stats["WIS"])
	set_dex(__allocated_stats["DEX"])
	set_luc(__allocated_stats["LUC"])

## Returns a copy of the allocated stats dictionary.
func get_stat_alloc() -> Dictionary:
	return __allocated_stats.duplicate()

# ─── Computed Stats ──────────────────────────────────────────────────────────
func update_current_health_and_mana():
	__base_stats["HP"] = get_max_hp()
	__base_stats["MP"] = get_max_mp()

func get_base_stats() -> Dictionary:
	return __base_stats

func get_base_stats_value(key: String) -> int:
	if __base_stats.keys().has(key):
		return __base_stats[key]
	printerr("The key " + key + " not found in the __base_stats dictionary")
	return 0

func get_stats_bonus() -> Dictionary:
	return __bonus_stats

func get_base_stat(key: String) -> int:
	return __base_stats.get(key, 0)

func add_stat_bonus(stat: String, value: int) -> void:
	if __bonus_stats.has(stat):
		__bonus_stats[stat] = max(0, __bonus_stats[stat] + value)

func remove_stat_bonus(stat: String, value: int) -> void:
	if __bonus_stats.has(stat):
		__bonus_stats[stat] = max(0, __bonus_stats[stat] - value)

func add_stat_bonuses(bonuses: Dictionary) -> void:
	for stat in bonuses:
		add_stat_bonus(stat, int(bonuses[stat]))

func remove_stat_bonuses(bonuses: Dictionary) -> void:
	for stat in bonuses:
		remove_stat_bonus(stat, int(bonuses[stat]))

## Returns a dictionary of primary stats with totals (base + bonus).
func get_primary_stats_breakdown() -> Dictionary:
	return {
		"STR": get_total("STR"),
		"REC": get_total("REC"),
		"INT": get_total("INT"),
		"WIS": get_total("WIS"),
		"DEX": get_total("DEX"),
		"LUC": get_total("LUC")
	}

## Returns a dictionary of all derived secondary combat stats.
func get_secondary_stats_breakdown() -> Dictionary:
	return {
		"max_hp": get_max_hp(),
		"max_mp": get_max_mp(),
		"def": get_physical_defense(),
		"resist": get_resist(),
		"attack_damage": get_attack_damage(),
		"attack_speed": get_attack_speed(),
		"attack_range": get_attack_range(),
		"movement_speed": get_movement_speed(),
		"cast_speed": get_casting_speed(),
		"melee_atk": get_melee_atk(),
		"ranged_atk": get_ranged_atk(),
		"magic_atk": get_magic_atk(),
		"crit_chance": get_crit_chance(),
		"crit_damage": get_crit_damage()
	}

func get_attack_damage():
	var total_attack_damage = get_total("attack_damage")
	var passive_attack_damage = __passive_stats.get("attack_damage", 0.0)
	var buff_attack_damage = __buff_stats.get("attack_damage", 0.0)
	return total_attack_damage + passive_attack_damage + buff_attack_damage

func get_attack_speed():
	var total_attack_speed = get_total("attack_speed")
	var passive_attack_speed = __passive_stats.get("attack_speed", 0.0)
	var buff_attack_speed = __buff_stats.get("attack_speed", 0.0)

	return total_attack_speed + passive_attack_speed + buff_attack_speed

func get_attack_range():
	var total_attack_range = get_total("attack_range")
	var buff_attack_range = __buff_stats.get("attack_range", 0.0)

	return total_attack_range + buff_attack_range

func get_movement_speed():
	var total_movement_speed = get_total("movement_speed")
	var buff_movement_speed = __buff_stats.get("movement_speed", 0.0)

	return total_movement_speed + buff_movement_speed

func get_casting_speed():
	var base_cast_speed = get_base_stat("cast_speed")
	var buff_cast_speed = __buff_stats.get("cast_speed", 0.0)

	return base_cast_speed + buff_cast_speed

func get_stats_bonus_value(stat: String) -> int:
	return __bonus_stats.get(stat, 0)

func get_base_weapon_power() -> float:
	return get_total("weapon_power")

func get_base_armor_defense() -> float:
	return get_total("armor_defense")

func get_base_armor_resist() -> float:
	return get_total("armor_resist")

## Calculates maximum health points.
func get_max_hp() -> float:
	var base_hp = 100.0
	var total_hp = (get_total("REC")) * 5.0
	var passive_hp = __passive_stats.get("max_hp", 0)
	var buff_hp = __buff_stats.get("max_hp", 0)
	return base_hp + total_hp  + passive_hp + buff_hp

## Calculates maximum mana points.
func get_max_mp() -> float:
	var base_mp = 50.0
	var total_mp = (get_total("WIS")) * 5.0
	var max_mp_bonus = get_bonus_max_mp()
	var passive_mp = __passive_stats.get("max_mp", 0)
	var buff_mp = __buff_stats.get("max_mp", 0)
	return base_mp + total_mp + max_mp_bonus + passive_mp + buff_mp

func get_current_hp() -> float:
	return __base_stats["HP"]

func get_current_mp() -> float:
	return __base_stats["MP"]

func set_current_hp(current_hp: float):
	if current_hp >= 0 and current_hp <= get_max_hp():
		__base_stats["HP"] = current_hp

func set_current_mp(current_mp: float):
	if current_mp >= 0 and current_mp <= get_max_mp():
		__base_stats["MP"] = current_mp

## Calculates physical defense.
func get_physical_defense() -> float:
	var total_rec = get_total("REC")
	var total_armor_defense = get_total("armor_defense")
	var passive_physical_defence = __passive_stats.get("physical_defence", 0.0)
	var buff_physical_defence = __buff_stats.get("physical_defence", 0.0)

	return total_rec + total_armor_defense + passive_physical_defence + buff_physical_defence

## Calculates magical resistance.
func get_resist() -> float:
	var total_wis = get_total("WIS")
	var total_armor_resist = get_total("armor_resist")
	var passive_magical_resistance = __passive_stats.get("magical_resistance", 0.0)
	var buff_magical_resistance = __buff_stats.get("magical_resistance", 0.0)

	return total_wis + total_armor_resist + passive_magical_resistance + buff_magical_resistance

## Calculates melee attack power.
func get_melee_atk() -> float:
	var total_str = floor(get_total("STR") * 1.3)
	var total_dex = floor(get_total("DEX") * 0.25)
	var total_weapon_power = get_total("weapon_power")
	var attack_damage = get_attack_damage()

	return total_str + total_dex + total_weapon_power + attack_damage

## Calculates ranged attack power.
func get_ranged_atk() -> float:
	var total_str = floor(get_total("STR") * 1.3)
	var total_luc = floor(get_total("LUC") * 0.3)
	var total_dex = floor(get_total("DEX") * 0.2)
	var total_weapon_power = get_total("weapon_power")
	var attack_damage = get_attack_damage()

	return total_str + total_luc + total_dex + total_weapon_power + attack_damage

## Calculates magic attack power.
func get_magic_atk() -> float:
	var total_int = floor(get_total("INT") * 1.3)
	var total_wis = floor(get_total("WIS") * 0.2)
	var total_weapon_power = get_total("weapon_power")
	var attack_damage = get_attack_damage()

	return total_int + total_wis + total_weapon_power + attack_damage

## Calculates critical hit chance percentage.
func get_crit_chance() -> float:
	var total_luc = floor(get_total("LUC") * 0.2)
	var buff_critical_chance = __buff_stats.get("critical_chance", 0.0)

	return total_luc + buff_critical_chance # percent

## Calculates critical hit damage multiplier.
func get_crit_damage() -> float:
	var total_luc = floor(get_total("LUC") * 0.0075)
	var passive_critical_damage = __passive_stats.get("critical_damage", 0.0)
	var buff_critical_damage = __buff_stats.get("critical_damage", 0.0)

	return 1.5 + total_luc + passive_critical_damage + buff_critical_damage # multiplier

func get_absorption():
	return __buff_stats.get("absorption", 0.0)

func set_str(new_str: float) -> void:
	__base_stats['STR'] = new_str

func set_rec(new_rec: float) -> void:
	__base_stats['REC'] = new_rec

func set_int(new_int: float) -> void:
	__base_stats['INT'] = new_int

func set_wis(new_wis: float) -> void:
	__base_stats['WIS'] = new_wis

func set_dex(new_dex: float) -> void:
	__base_stats['DEX'] = new_dex

func set_luc(new_luc: float) -> void:
	__base_stats['LUC'] = new_luc

## Calculates bonus maximum health points.
func get_bonus_max_hp() -> float:
	return get_stats_bonus_value("max_health")

## Calculates bonus maximum mana points.
func get_bonus_max_mp() -> float:
	return get_stats_bonus_value("max_mana")

## Calculates bonus strength.
func get_bonus_str() -> int:
	return get_stats_bonus_value("STR")

## Calculates bonus recupration.
func get_bonus_rec() -> int:
	return get_stats_bonus_value("REC")

## Calculates bonus intelligence.
func get_bonus_int() -> int:
	return get_stats_bonus_value("INT")

## Calculates bonus wisdom.
func get_bonus_wis() -> int:
	return get_stats_bonus_value("WIS")

## Calculates bonus dexterity.
func get_bonus_dex() -> int:
	return get_stats_bonus_value("DEX")

## Calculates bonus luck.
func get_bonus_luc() -> int:
	return get_stats_bonus_value("LUC")

## Calculates bonus weapon power.
func get_bonus_weapon_power() -> float:
	return get_stats_bonus_value("weapon_power")

## Calculates bonus armor defense.
func get_bonus_armor_defense() -> float:
	return get_stats_bonus_value("armor_defense")

## Calculates bonus armor resistance.
func get_bonus_armor_resist() -> float:
	return get_stats_bonus_value("armor_resist")

func get_total(key: String) -> int:
	return get_base_stats_value(key) + get_stats_bonus_value(key)

## Converts base stats to a dictionary format.
func to_dict() -> Dictionary:
	return {
		"max_health": get_max_hp(),
		"max_mana": get_max_mp(),
		"STR": get_base_stat("STR"),
		"REC": get_base_stat("REC"),
		"INT": get_base_stat("INT"),
		"WIS": get_base_stat("WIS"),
		"DEX": get_base_stat("DEX"),
		"LUC": get_base_stat("LUC")
	}

func set_passive_stat(_skill: PassiveSkill) -> void:
	var dic = _skill.get_value()
	var key = dic["stat_type"]
	var is_percent = dic['is_percentage_value']
	var stat_value = dic["value"]

	if not __passive_stats.has(key):
		push_error("Key '" + key + "' not found in __passive_stats")
		return

	if is_percent:
		var percent = stat_value / 100.0
		match key:
			"max_hp":
				var total_hp = 100.0 + (get_total("REC") * 5.0)
				__passive_stats[key] = total_hp * percent
			"max_mp":
				var total_mp = 50.0 + (get_total("WIS") * 5.0)
				__passive_stats[key] = total_mp * percent
			"attack_damage":
				__passive_stats[key] = get_total("attack_damage") * percent
			"movement_speed":
				__passive_stats[key] = get_total("movement_speed") * percent
			"physical_defence":
				var phys_def = get_total("REC") + get_total("armor_defense")
				__passive_stats[key] = phys_def * percent
			"magical_resistance":
				var mag_res = get_total("WIS") + get_total("armor_resist")
				__passive_stats[key] = mag_res * percent
			"critical_damage":
				# أو percent حسب كيفاش مخدوم عندك crit_damage
				__passive_stats[key] = percent 
			_:
				__passive_stats[key] = 0.0
	else:
		match key:
			"max_hp", "max_mp", "attack_damage", "movement_speed", "physical_defence", "magical_resistance", "critical_damage":
				__passive_stats[key] = stat_value
			_:
				__passive_stats[key] = 0.0

func set_buff_stat(_skill: BuffSkill) -> float:
	var dic = _skill.get_value()
	var key = dic["stat_type"]
	var is_percent = dic['is_percentage_value']
	var stat_value = dic["value"]
	var value: float = 0.0
	if not __buff_stats.has(key):
		push_error("Key '" + key + "' not found in __buff_stats")
		return value

	if is_percent:
		var percent = stat_value / 100.0
		match key:
			# Primary Stats (كنحسبو النسبة على Base + Bonus ديال الخصائص الأساسية)
			"STR", "REC", "INT", "WIS", "DEX", "LUC":
				value = get_total(key) * percent
				__buff_stats[key] = value

			# Derived Combat Stats
			"max_hp":
				var total_hp = 100.0 + (get_total("REC") * 5.0)
				value = total_hp * percent
				__buff_stats[key] = value
			"max_mp":
				var total_mp = 50.0 + (get_total("WIS") * 5.0)
				value = total_mp * percent
				__buff_stats[key] = value
			"attack_damage":
				value = get_total("attack_damage") * percent
				__buff_stats[key] = value
			"attack_speed":
				value = get_total("attack_speed") * percent
				__buff_stats[key] = value
			"attack_range":
				value = get_total("attack_range") * percent
				__buff_stats[key] = value
			"movement_speed":
				value = get_total("movement_speed") * percent
				__buff_stats[key] = value
			"physical_defence":
				var phys_def = get_total("REC") + get_total("armor_defense")
				value = phys_def * percent
				__buff_stats[key] = value
			"magical_resistance":
				var mag_res = get_total("WIS") + get_total("armor_resist")
				value = mag_res * percent
				__buff_stats[key] = value
			
			# الستاتات الخاصة اللي كيتعاملوا كمعاملات أو نسب مباشرة
			"critical_chance", "critical_damage", "absorption":
				value = percent
				__buff_stats[key] = value
			_:
				__buff_stats[key] = 0.0
	else:
		# إيلا كانت القيمة ثابتة (Flat)، كتتضاف مباشرة لأي Stat فالمجموعة
		match key:
			"STR", "REC", "INT", "WIS", "DEX", "LUC", "max_hp", "max_mp", "attack_damage", "attack_speed", "attack_range", "movement_speed", "physical_defence", "magical_resistance", "critical_chance", "critical_damage", "absorption":
				value = stat_value
				__buff_stats[key] = value
			_:
				__buff_stats[key] = 0.0

	return value

func add_buff_stat(key: String, delta: float) -> void:
	if __buff_stats.has(key):
		__buff_stats[key] = float(__buff_stats[key]) + delta
	else:
		push_error("Key '" + key + "' not found in __buff_stats")

func remove_buff_stat(key: String, delta: float) -> void:
	if __buff_stats.has(key):
		__buff_stats[key] = float(__buff_stats[key]) - delta
	else:
		push_error("Key '" + key + "' not found in __buff_stats")
