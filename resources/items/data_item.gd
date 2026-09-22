extends Resource
class_name DataItem

@export var item_id: String = ""
@export var item_name: String = ""
@export var price: int = 0
@export var max_stack: int = 1
@export var grid_coordinate: Vector2 = Vector2.ZERO
@export var cell_size: Vector2 = Vector2(64, 64)

## Backward compatibility alias for item_id
var id: String:
	get: return item_id
	set(value): item_id = value

func _init(
	_item_id: String = "",
	_item_name: String = "",
	_price: int = 0,
	_max_stack: int = 1,
	_grid_coordinate: Vector2 = Vector2.ZERO,
	_cell_size: Vector2 = Vector2(64, 64)
) -> void:
	item_id = _item_id
	item_name = _item_name
	price = _price
	max_stack = _max_stack
	grid_coordinate = _grid_coordinate
	cell_size = _cell_size

func get_item_texture() -> AtlasTexture:
	return null
