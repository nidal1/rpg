@tool
class_name ExampleItemUser
extends Node

## Exported array of item IDs configured via Item DB Selector inspector plugin
@export var custom_db_item_objects: Array[Dictionary] = []
@export var texture_image: Sprite2D

func _ready():
	if Engine.is_editor_hint():
		return
		
	# Mma محتاجch t-loady JSON marra khra f runtime! L-data kamla kayna hna:
	for item in custom_db_item_objects:
		print("ID: ", item.get("id"))
		print("Name: ", item.get("name"))
		print("Damage: ", item.get("base_damage", 0))
		print("Grid Coord: ", item.get("grid_coordinate"))
		texture_image.texture = get_item_texture(item)
		print("---------------------------------")


func get_item_texture(item_data: Dictionary) -> AtlasTexture:
	var tex_path = item_data.get("texture_path", "res://assets/sprites/items/weapons.png")
	var grid_coord = item_data.get("grid_coordinate", {"column_x": 0, "row_y": 0})
	var cell_size = Vector2(64, 64)
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(tex_path)
	atlas_tex.region = Rect2(
		grid_coord["column_x"] * cell_size.x,
		grid_coord["row_y"] * cell_size.y,
		cell_size.x,
		cell_size.y
	)
	return atlas_tex
