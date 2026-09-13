@tool
class_name ExampleItemUser
extends Node

## Exported array of item IDs configured via Item DB Selector inspector plugin
@export var custom_db_item_objects: Array[Dictionary] = []


func _ready():
	if Engine.is_editor_hint():
		return
		
	# Mma محتاجch t-loady JSON marra khra f runtime! L-data kamla kayna hna:
	for item in custom_db_item_objects:
		print("ID: ", item.get("id"))
		print("Name: ", item.get("name"))
		print("Damage: ", item.get("base_damage", 0))
		print("Grid Coord: ", item.get("grid_coordinate"))
		print("---------------------------------")