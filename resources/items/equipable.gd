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


func get_effective_stats_breakdown() -> Dictionary:
	# return only the positive stats
	var gem_bonus = get_gems_stats_bonus()
	var bonus = {}
	for sb in stat_bonus:
		if stat_bonus[sb] > 0:
			bonus[sb] = {"base": stat_bonus[sb], "gem": 0}
			if gem_bonus.has(sb):
				bonus[sb]["gem"] = gem_bonus[sb]
	for g in gem_bonus:
		if not bonus.has(g):
			bonus[g] = {"base": 0, "gem": gem_bonus[g]}
	return bonus

func get_gems_stats_bonus():
	var _bonus = {}
	if gems.size():
		for gem in gems:
			match gem.gem_type:
				Gem.GemType.RUBY:
					_bonus["DEX"] = gem.get_dex_bonus()
				Gem.GemType.SAPPHIRE:
					_bonus["STR"] = gem.get_str_bonus()
				Gem.GemType.EMERALD:
					_bonus["LUC"] = gem.get_luc_bonus()
				Gem.GemType.TOPAZ:
					_bonus["INT"] = gem.get_int_bonus()
				Gem.GemType.AMETHYST:
					_bonus["WIS"] = gem.get_wis_bonus()
				Gem.GemType.DIAMOND:
					_bonus["REC"] = gem.get_rec_bonus()
	return _bonus

func get_stats_bonus_value(stat: String) -> int:
	return stat_bonus[stat]

func add_gems_bonus():
	if gems.size():
		for gem in gems:
			match gem.gem_type:
				Gem.GemType.RUBY:
					stat_bonus["DEX"] += gem.get_dex_bonus()
				Gem.GemType.SAPPHIRE:
					stat_bonus["STR"] += gem.get_str_bonus()
				Gem.GemType.EMERALD:
					stat_bonus["LUC"] += gem.get_luc_bonus()
				Gem.GemType.TOPAZ:
					stat_bonus["INT"] += gem.get_int_bonus()
				Gem.GemType.AMETHYST:
					stat_bonus["WIS"] += gem.get_wis_bonus()
				Gem.GemType.DIAMOND:
					stat_bonus["REC"] += gem.get_rec_bonus()

func remove_gems_bonus():
	if gems.size():
		for gem in gems:
			match gem.gem_type:
				Gem.GemType.RUBY:
					stat_bonus["DEX"] -= gem.get_dex_bonus()
				Gem.GemType.SAPPHIRE:
					stat_bonus["STR"] -= gem.get_str_bonus()
				Gem.GemType.EMERALD:
					stat_bonus["LUC"] -= gem.get_luc_bonus()
				Gem.GemType.TOPAZ:
					stat_bonus["INT"] -= gem.get_int_bonus()
				Gem.GemType.AMETHYST:
					stat_bonus["WIS"] -= gem.get_wis_bonus()
				Gem.GemType.DIAMOND:
					stat_bonus["REC"] -= gem.get_rec_bonus()
