extends DataItem
class_name EquipableItem

enum EquipmentCategory {
	WEAPON,
	ARMOR,
	ACCESSORY
}

enum ArmorType {
	SHIELD,
	CHEST,
	HEAD,
	LEGS_FEET,
	FEET,
	RING,
	NECKLACE,
}

enum WeaponType {
	DAGGER,
	SWORD,
	TWO_HANDED_SWORD,
	MELEE,
	TOOL_MELEE,
	AXE,
	TOOL_AXE,
	TWO_HANDED_AXE,
	MACE,
	TWO_HANDED_MACE,
	BOW,
	CROSSBOW,
	THROWING,
	POLEARM,
	STAFF,
	WAND
}

@export var equipment_type: String = ""
@export var player_class: String = "ALL"
@export var required_level: int = 1
@export var base_damage: int = 0
@export var base_defense: int = 0
@export var upgrade_level: int = 0
@export var tradable: bool = true
@export var gems_slots_count: int = 0
@export var gems: Array[Gem] = [] # max 2-3 slots
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

const WEAPONS_ATLAS_PATH = "res://assets/sprites/items/weapons.png"
const ARMORS_ATLAS_PATH = "res://assets/sprites/items/armors.png"

func _init(
	_item_id: String = "",
	_item_name: String = "",
	_price: int = 0,
	_max_stack: int = 1,
	_grid_coordinate: Vector2 = Vector2.ZERO,
	_cell_size: Vector2 = Vector2(64, 64),
	_equipment_type: String = "",
	_player_class: String = "ALL",
	_required_level: int = 1,
	_base_damage: int = 0,
	_base_defense: int = 0
) -> void:
	super(_item_id, _item_name, _price, _max_stack, _grid_coordinate, _cell_size)
	equipment_type = _equipment_type
	player_class = _player_class
	required_level = _required_level
	base_damage = _base_damage
	base_defense = _base_defense

func is_armor() -> bool:
	var eq_upper = equipment_type.to_upper()
	return eq_upper in ArmorType.keys()

func get_item_texture() -> AtlasTexture:
	var atlas_path = ARMORS_ATLAS_PATH if is_armor() else WEAPONS_ATLAS_PATH
	if not ResourceLoader.exists(atlas_path):
		return null
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(atlas_path)
	atlas_tex.region = Rect2(
		grid_coordinate.x * cell_size.x,
		grid_coordinate.y * cell_size.y,
		cell_size.x,
		cell_size.y
	)
	return atlas_tex


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