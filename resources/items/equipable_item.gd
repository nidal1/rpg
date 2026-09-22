extends DataItem
class_name EquipableItem

@export var equipment_type: String = ""
@export var player_class: String = "ALL"
@export var required_level: int = 1
@export var base_damage: int = 0
@export var base_defense: int = 0

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
	return eq_upper in ["CHEST", "HELMET", "HEAD", "BOOTS", "LEGS", "FEET", "SHIELD", "RING", "NECKLACE", "AMULET", "CLOAK", "ARMOR", "ARMORS"]

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
