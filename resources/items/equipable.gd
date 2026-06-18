class_name Equipable
extends Item


@export var player_type: CharacterClass.PlayerType = CharacterClass.PlayerType.ALL
@export var upgrade_level: int = 0
@export var tradable: bool = true
@export var gems_slots_count: int
@export var gems: Array[Gem] = [] # max 2-3 slots
@export var level: int = 1
@export var stat_bonus: CharacterStats

func get_gems() -> Array[Gem]:
	return gems

func _add_gem(gem: Gem) -> void:
	if gems.size() < gems_slots_count:
		gems.append(gem)
	else:
		print("No more slots for gems")

func _remove_gem(gem: Gem) -> void:
	if gem in gems:
		gems.erase(gem)

func get_stat_bonus() -> CharacterStats:
	return stat_bonus

func get_assigned_stats_bonus():
	if not stat_bonus:
		return null
	# return only the positive stats
	var bonus = {}
	if stat_bonus.max_health > 0:
		bonus["max_health"] = stat_bonus.max_health
	if stat_bonus.max_mana > 0:
		bonus["max_mana"] = stat_bonus.max_mana
	if stat_bonus.STR > 0:
		bonus["STR"] = stat_bonus.STR
	if stat_bonus.DEX > 0:
		bonus["DEX"] = stat_bonus.DEX
	if stat_bonus.INT > 0:
		bonus["INT"] = stat_bonus.INT
	if stat_bonus.REC > 0:
		bonus["REC"] = stat_bonus.REC
	if stat_bonus.WIS > 0:
		bonus["WIS"] = stat_bonus.WIS
	if stat_bonus.LUC > 0:
		bonus["LUC"] = stat_bonus.LUC
	return bonus
