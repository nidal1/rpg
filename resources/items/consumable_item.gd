extends DataItem
class_name ConsumableItem

@export var heal_amount: int = 0
@export var potion_type: String = "HEALTH"

const POTIONS_ATLAS_PATH = "res://assets/sprites/items/potions.png"

func _init(
	_item_id: String = "",
	_item_name: String = "",
	_price: int = 0,
	_max_stack: int = 20,
	_grid_coordinate: Vector2 = Vector2.ZERO,
	_cell_size: Vector2 = Vector2(64, 64),
	_heal_amount: int = 0,
	_potion_type: String = "HEALTH"
) -> void:
	super(_item_id, _item_name, _price, _max_stack, _grid_coordinate, _cell_size)
	heal_amount = _heal_amount
	potion_type = _potion_type

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
