@tool
extends Node

## Example script demonstrating how to use the custom @export property for selecting DataItems from the database.

@export var custom_db_item_objects: Array[DataItem] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	print("--- Loaded Items from Database Selector ---")
	for item in custom_db_item_objects:
		print("Item ID: ", item.item_id)
		print("Item Name: ", item.item_name)
		print("Price: ", item.price)
		print("Max Stack: ", item.max_stack)
		print("Grid Coords: ", item.grid_coordinate)
		
		if item is EquipableItem:
			var eq = item as EquipableItem
			print("Type: Equipable | EqType: ", eq.equipment_type, " | Class: ", eq.player_class, " | ReqLvl: ", eq.required_level)
			print("Damage: ", eq.base_damage, " | Defense: ", eq.base_defense)
		elif item is ConsumableItem:
			var cons = item as ConsumableItem
			print("Type: Consumable | Heal: ", cons.heal_amount, " | PotionType: ", cons.potion_type)
		elif item is QuestItem:
			var q = item as QuestItem
			print("Type: QuestItem | QuestID: ", q.quest_id, " | Description: ", q.description)
		print("---------------------------------")
