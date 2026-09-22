@tool
extends MainLoop

func _process(_delta: float) -> bool:
	print("--- Starting Item System Verification ---")
	
	# 1. Verify JSON file exists & loads
	var path = "res://data/data_items.json"
	if not FileAccess.file_exists(path):
		print("ERROR: File missing: ", path)
		return true
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		print("ERROR: JSON parse failed: ", json.get_error_message())
		return true
		
	var db = json.get_data()
	print("JSON Database loaded successfully.")
	
	# 2. Check Root Categories
	assert(db.has("equipables"), "Missing 'equipables' root category")
	assert(db.has("consumables"), "Missing 'consumables' root category")
	assert(db.has("quest_items"), "Missing 'quest_items' root category")
	print("Root categories verified: equipables, consumables, quest_items")
	
	# 3. Test EquipableItem Instantiation
	var weapons = db["equipables"]["weapons"]
	assert(weapons.size() > 0, "Weapons array is empty")
	var w0 = weapons[0]
	var w_item = EquipableItem.new(
		str(w0["item_id"]),
		str(w0["item_name"]),
		int(w0["price"]),
		int(w0["max_stack"]),
		Vector2(w0["grid_coordinate"][0], w0["grid_coordinate"][1]),
		Vector2(w0["cell_size"][0], w0["cell_size"][1]),
		str(w0["equipment_type"]),
		str(w0["player_class"]),
		int(w0["required_level"]),
		int(w0["base_damage"]),
		0
	)
	print("Instantiated EquipableItem: ", w_item.item_id, " | Name: ", w_item.item_name, " | Damage: ", w_item.base_damage)
	var w_tex = w_item.get_item_texture()
	assert(w_tex != null, "EquipableItem texture is null")
	print("EquipableItem texture region: ", w_tex.region)
	
	# 4. Test ConsumableItem Instantiation
	var consumables = db["consumables"]
	assert(consumables.size() > 0, "Consumables array is empty")
	var c0 = consumables[0]
	var c_item = ConsumableItem.new(
		str(c0["item_id"]),
		str(c0["item_name"]),
		int(c0["price"]),
		int(c0["max_stack"]),
		Vector2(c0["grid_coordinate"][0], c0["grid_coordinate"][1]),
		Vector2(c0["cell_size"][0], c0["cell_size"][1]),
		int(c0["heal_amount"]),
		str(c0["potion_type"])
	)
	print("Instantiated ConsumableItem: ", c_item.item_id, " | Name: ", c_item.item_name, " | Heal: ", c_item.heal_amount)
	var c_tex = c_item.get_item_texture()
	assert(c_tex != null, "ConsumableItem texture is null")
	print("ConsumableItem texture region: ", c_tex.region)

	# 5. Test QuestItem Instantiation
	var quest_items = db["quest_items"]
	assert(quest_items.size() > 0, "Quest items array is empty")
	var q0 = quest_items[0]
	var q_item = QuestItem.new(
		str(q0["item_id"]),
		str(q0["item_name"]),
		int(q0["price"]),
		int(q0["max_stack"]),
		Vector2(q0["grid_coordinate"][0], q0["grid_coordinate"][1]),
		Vector2(q0["cell_size"][0], q0["cell_size"][1]),
		str(q0["quest_id"]),
		str(q0["description"])
	)
	print("Instantiated QuestItem: ", q_item.item_id, " | Name: ", q_item.item_name, " | QuestID: ", q_item.quest_id)
	var q_tex = q_item.get_item_texture()
	assert(q_tex != null, "QuestItem texture is null")
	print("QuestItem texture region: ", q_tex.region)
	
	print("--- ALL VERIFICATION TESTS PASSED SUCCESSFULLY ---")
	return true
