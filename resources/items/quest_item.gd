extends DataItem
class_name QuestItem

@export var quest_id: String = ""
@export var description: String = ""

const POTIONS_ATLAS_PATH = "res://assets/sprites/items/potions.png"

func _init(
	_item_id: String = "",
	_item_name: String = "",
	_price: int = 0,
	_max_stack: int = 1,
	_grid_coordinate: Vector2 = Vector2.ZERO,
	_cell_size: Vector2 = Vector2(64, 64),
	_quest_id: String = "",
	_description: String = ""
) -> void:
	super(_item_id, _item_name, _price, _max_stack, _grid_coordinate, _cell_size)
	quest_id = _quest_id
	description = _description

func get_item_texture() -> AtlasTexture:
	if not ResourceLoader.exists(POTIONS_ATLAS_PATH):
		return null
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(POTIONS_ATLAS_PATH)
	atlas_tex.region = Rect2(
		grid_coordinate.x * cell_size.x,
		grid_coordinate.y * cell_size.y,
		cell_size.x,
		cell_size.y
	)
	return atlas_tex
