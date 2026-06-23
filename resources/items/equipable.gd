class_name Equipable
extends Item


@export var player_type: CharacterClass.PlayerType = CharacterClass.PlayerType.ALL
@export var upgrade_level: int = 0
@export var tradable: bool = true
@export var gems_slots_count: int
@export var gems: Array[Gem] = [] # max 2-3 slots
@export var level: int = 1
@export var stat_bonus: Dictionary = {
	"max_health": 0,
	"max_mana": 0,
	"STR": 0,
	"REC": 0,
	"INT": 0,
	"WIS": 0,
	"DEX": 0,
	"LUC": 0,
	"weapon_power": 0,
	"armor_defense": 0,
	"armor_resist": 0
}

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

func get_stat_bonus() -> Dictionary:
	return stat_bonus

func get_assigned_stats_bonus():
	if not stat_bonus:
		return null
	# return only the positive stats
	var bonus = {}
	for sb in stat_bonus:
		if stat_bonus[sb] > 0:
			bonus[sb] = stat_bonus[sb]
	return bonus
