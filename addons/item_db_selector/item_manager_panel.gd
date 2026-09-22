@tool
extends Control

## Main Screen Tab Panel for managing res://data/data_items.json in Godot Editor.

const DB_PATH = "res://data/data_items.json"
const ALT_DB_PATH = "res://data/items_data.json"
const WEAPONS_ATLAS_PATH = "res://assets/sprites/items/weapons.png"
const ARMORS_ATLAS_PATH = "res://assets/sprites/items/armors.png"
const POTIONS_ATLAS_PATH = "res://assets/sprites/items/potions.png"
const CELL_SIZE = Vector2i(64, 64)

# Data State
var current_db_data: Dictionary = {}
var selected_tree_item: TreeItem = null
var selected_item_dict: Dictionary = {}
var selected_root_key: String = ""
var selected_category_name: String = ""

# Textures
var _weapons_texture: Texture2D
var _armors_texture: Texture2D
var _potions_texture: Texture2D

# UI References - Top Bar
var _save_button: Button
var _reload_button: Button
var _status_label: Label

# UI References - Left Panel
var _tree: Tree
var _btn_add_category: Button
var _btn_add_item: Button
var _btn_delete_selected: Button

# UI References - Right Edit Form
var _form_container: Control
var _no_selection_label: Label
var _edit_id: LineEdit
var _edit_name: LineEdit
var _edit_type: LineEdit
var _edit_player_type: LineEdit
var _edit_level: SpinBox
var _edit_stat: SpinBox
var _stat_label: Label
var _edit_col_x: SpinBox
var _edit_row_y: SpinBox
var _preview_rect: TextureRect
var _preview_info_label: Label
var _edit_price: SpinBox
var _edit_max_stack: SpinBox

# Dialogs
var _add_category_dialog: ConfirmationDialog
var _category_name_input: LineEdit

var _is_updating_form: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		pass
	
	_load_textures()
	_build_ui()
	_load_and_populate_db()


func _load_textures() -> void:
	if ResourceLoader.exists(WEAPONS_ATLAS_PATH):
		_weapons_texture = load(WEAPONS_ATLAS_PATH)
	if ResourceLoader.exists(ARMORS_ATLAS_PATH):
		_armors_texture = load(ARMORS_ATLAS_PATH)
	if ResourceLoader.exists(POTIONS_ATLAS_PATH):
		_potions_texture = load(POTIONS_ATLAS_PATH)


func _build_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)
	
	var margin = MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	main_vbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(content_vbox)
	
	# Top Action Bar
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	content_vbox.add_child(top_bar)
	
	var title_label = Label.new()
	title_label.text = "Item Database Manager"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	top_bar.add_child(title_label)
	
	var v_sep = VSeparator.new()
	top_bar.add_child(v_sep)
	
	_save_button = Button.new()
	_save_button.text = "Save Database"
	_save_button.pressed.connect(_on_save_button_pressed)
	top_bar.add_child(_save_button)
	
	_reload_button = Button.new()
	_reload_button.text = "Reload Database"
	_reload_button.pressed.connect(_load_and_populate_db)
	top_bar.add_child(_reload_button)
	
	_status_label = Label.new()
	_status_label.text = "Ready"
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	top_bar.add_child(_status_label)
	
	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 260
	content_vbox.add_child(split)
	
	# Left Panel
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_vbox.custom_minimum_size = Vector2(400, 600)
	split.add_child(left_vbox)
	
	var tree_header = Label.new()
	tree_header.text = "Database Hierarchy"
	tree_header.add_theme_font_size_override("font_size", 14)
	left_vbox.add_child(tree_header)
	
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.select_mode = Tree.SELECT_SINGLE
	_tree.item_selected.connect(_on_tree_item_selected)
	left_vbox.add_child(_tree)
	
	var left_btn_bar = HBoxContainer.new()
	left_btn_bar.add_theme_constant_override("separation", 6)
	left_vbox.add_child(left_btn_bar)
	
	_btn_add_category = Button.new()
	_btn_add_category.text = "+ Category"
	_btn_add_category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_add_category.pressed.connect(_on_add_category_pressed)
	left_btn_bar.add_child(_btn_add_category)
	
	_btn_add_item = Button.new()
	_btn_add_item.text = "+ Item"
	_btn_add_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_add_item.pressed.connect(_on_add_item_pressed)
	left_btn_bar.add_child(_btn_add_item)
	
	_btn_delete_selected = Button.new()
	_btn_delete_selected.text = "Delete"
	_btn_delete_selected.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_delete_selected.pressed.connect(_on_delete_selected_pressed)
	left_btn_bar.add_child(_btn_delete_selected)
	
	# Right Panel: Edit Form
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right_panel)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 16)
	right_margin.add_theme_constant_override("margin_top", 16)
	right_margin.add_theme_constant_override("margin_right", 16)
	right_margin.add_theme_constant_override("margin_bottom", 16)
	right_panel.add_child(right_margin)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 16)
	right_margin.add_child(right_vbox)
	
	_no_selection_label = Label.new()
	_no_selection_label.text = "Select an item from the left tree hierarchy to edit its properties."
	_no_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_selection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_no_selection_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_no_selection_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	right_vbox.add_child(_no_selection_label)
	
	_form_container = VBoxContainer.new()
	_form_container.add_theme_constant_override("separation", 16)
	_form_container.visible = false
	right_vbox.add_child(_form_container)
	
	var form_header = Label.new()
	form_header.text = "Item Properties & Preview"
	form_header.add_theme_font_size_override("font_size", 16)
	form_header.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	_form_container.add_child(form_header)
	
	var form_split = HBoxContainer.new()
	form_split.add_theme_constant_override("separation", 24)
	_form_container.add_child(form_split)
	
	var fields_grid = GridContainer.new()
	fields_grid.columns = 2
	fields_grid.add_theme_constant_override("h_separation", 12)
	fields_grid.add_theme_constant_override("v_separation", 10)
	fields_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_split.add_child(fields_grid)
	
	fields_grid.add_child(_create_label("Item ID:"))
	_edit_id = LineEdit.new()
	_edit_id.text_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_id)
	
	fields_grid.add_child(_create_label("Name:"))
	_edit_name = LineEdit.new()
	_edit_name.text_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_name)
	
	fields_grid.add_child(_create_label("Type/Eq Type:"))
	_edit_type = LineEdit.new()
	_edit_type.text_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_type)

	fields_grid.add_child(_create_label("Player Class:"))
	_edit_player_type = LineEdit.new()
	_edit_player_type.placeholder_text = "WARRIOR, ARCHER, MAGE, PRIEST, ALL"
	_edit_player_type.text_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_player_type)
	
	fields_grid.add_child(_create_label("Required Level:"))
	_edit_level = SpinBox.new()
	_edit_level.min_value = 1
	_edit_level.max_value = 100
	_edit_level.value_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_level)
	
	_stat_label = _create_label("Base Damage:")
	fields_grid.add_child(_stat_label)
	_edit_stat = SpinBox.new()
	_edit_stat.min_value = 0
	_edit_stat.max_value = 9999
	_edit_stat.value_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_stat)

	fields_grid.add_child(_create_label("Price (Gold):"))
	_edit_price = SpinBox.new()
	_edit_price.min_value = 0
	_edit_price.max_value = 999999
	_edit_price.value_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_price)

	fields_grid.add_child(_create_label("Max Stack:"))
	_edit_max_stack = SpinBox.new()
	_edit_max_stack.min_value = 1
	_edit_max_stack.max_value = 999
	_edit_max_stack.value_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_max_stack)
	
	fields_grid.add_child(_create_label("Grid Column X:"))
	_edit_col_x = SpinBox.new()
	_edit_col_x.min_value = 0
	_edit_col_x.max_value = 64
	_edit_col_x.value_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_col_x)
	
	fields_grid.add_child(_create_label("Grid Row Y:"))
	_edit_row_y = SpinBox.new()
	_edit_row_y.min_value = 0
	_edit_row_y.max_value = 64
	_edit_row_y.value_changed.connect(_on_field_value_changed)
	fields_grid.add_child(_edit_row_y)
	
	var preview_vbox = VBoxContainer.new()
	preview_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	preview_vbox.add_theme_constant_override("separation", 8)
	preview_vbox.custom_minimum_size = Vector2(180, 0)
	form_split.add_child(preview_vbox)
	
	var preview_title = Label.new()
	preview_title.text = "Sprite Preview (64x64):"
	preview_vbox.add_child(preview_title)
	
	var prev_panel = PanelContainer.new()
	preview_vbox.add_child(prev_panel)
	
	_preview_rect = TextureRect.new()
	_preview_rect.custom_minimum_size = Vector2(128, 128)
	_preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prev_panel.add_child(_preview_rect)
	
	_preview_info_label = Label.new()
	_preview_info_label.text = "Atlas: weapons.png"
	_preview_info_label.add_theme_font_size_override("font_size", 11)
	_preview_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	preview_vbox.add_child(_preview_info_label)
	
	_create_add_category_dialog()


func _create_label(text_str: String) -> Label:
	var l = Label.new()
	l.text = text_str
	return l


func _create_add_category_dialog() -> void:
	_add_category_dialog = ConfirmationDialog.new()
	_add_category_dialog.title = "Add New Category"
	_add_category_dialog.min_size = Vector2i(350, 120)
	add_child(_add_category_dialog)
	
	var dialog_vbox = VBoxContainer.new()
	dialog_vbox.add_theme_constant_override("separation", 8)
	_add_category_dialog.add_child(dialog_vbox)
	
	var dlg_label = Label.new()
	dlg_label.text = "Enter category key name (e.g. weapons, armors, potions):"
	dialog_vbox.add_child(dlg_label)
	
	_category_name_input = LineEdit.new()
	_category_name_input.placeholder_text = "weapons"
	dialog_vbox.add_child(_category_name_input)
	
	_add_category_dialog.confirmed.connect(_on_add_category_dialog_confirmed)


func _load_and_populate_db() -> void:
	current_db_data.clear()
	_tree.clear()
	_clear_form_selection()
	
	var target_path = DB_PATH if FileAccess.file_exists(DB_PATH) else ALT_DB_PATH
	if not FileAccess.file_exists(target_path):
		_show_status("Error: Database file not found at " + target_path, true)
		return
	
	var file = FileAccess.open(target_path, FileAccess.READ)
	if not file:
		_show_status("Error: Cannot open database file.", true)
		return
	
	var json_str = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		_show_status("JSON Parse Error: " + json.get_error_message(), true)
		return
	
	current_db_data = json.get_data()
	
	var root_tree_item = _tree.create_item()
	root_tree_item.set_text(0, "Item Database")
	root_tree_item.set_metadata(0, {"type": "root"})
	
	for root_key in current_db_data:
		var root_val = current_db_data[root_key]
		var root_node = _tree.create_item(root_tree_item)
		root_node.set_text(0, root_key.capitalize())
		root_node.set_metadata(0, {"type": "root_category", "root_key": root_key})
		
		if root_val is Dictionary:
			for cat_key in root_val:
				var items_list = root_val[cat_key]
				if not items_list is Array:
					continue
				var cat_node = _tree.create_item(root_node)
				cat_node.set_text(0, cat_key.capitalize().replace("_", " "))
				cat_node.set_metadata(0, {"type": "category", "root_key": root_key, "cat_key": cat_key})
				
				for i in range(items_list.size()):
					var item = items_list[i]
					if not item is Dictionary:
						continue
					_add_item_to_tree(cat_node, item, root_key, cat_key, i)
		elif root_val is Array:
			for i in range(root_val.size()):
				var item = root_val[i]
				if not item is Dictionary:
					continue
				_add_item_to_tree(root_node, item, root_key, "", i)
	
	_show_status("Database loaded successfully.")


func _add_item_to_tree(parent_node: TreeItem, item: Dictionary, root_key: String, cat_key: String, index: int) -> void:
	var item_node = _tree.create_item(parent_node)
	var item_id = str(item.get("item_id", item.get("id", "unk")))
	var item_name = str(item.get("item_name", "Unknown"))
	item_node.set_text(0, item_name + " [" + item_id + "]")
	item_node.set_metadata(0, {
		"type": "item",
		"root_key": root_key,
		"cat_key": cat_key,
		"item_index": index,
		"item_dict": item
	})


func _on_tree_item_selected() -> void:
	var item = _tree.get_selected()
	if item == null:
		_clear_form_selection()
		return
	
	selected_tree_item = item
	var meta = item.get_metadata(0)
	if not meta is Dictionary:
		_clear_form_selection()
		return
	
	var meta_type = meta.get("type", "")
	if meta_type == "item":
		selected_root_key = meta.get("root_key", "")
		selected_category_name = meta.get("cat_key", "")
		selected_item_dict = meta.get("item_dict", {})
		_populate_edit_form(selected_item_dict, selected_root_key, selected_category_name)
	else:
		_clear_form_selection()


func _clear_form_selection() -> void:
	selected_tree_item = null
	selected_item_dict = {}
	_form_container.visible = false
	_no_selection_label.visible = true


func _populate_edit_form(item_dict: Dictionary, root_key: String, cat_key: String) -> void:
	_is_updating_form = true
	
	_no_selection_label.visible = false
	_form_container.visible = true
	
	_edit_id.text = str(item_dict.get("item_id", item_dict.get("id", "")))
	_edit_name.text = str(item_dict.get("item_name", "Unknown"))
	_edit_type.text = str(item_dict.get("equipment_type", item_dict.get("item_type", "")))
	_edit_player_type.text = str(item_dict.get("player_class", item_dict.get("player_type", "ALL")))
	_edit_level.value = int(item_dict.get("required_level", 1))
	_edit_price.value = int(item_dict.get("price", 0))
	_edit_max_stack.value = int(item_dict.get("max_stack", 1))

	if root_key == "equipables" or cat_key in ["weapons", "armors"]:
		if cat_key == "armors" or "armor" in str(item_dict.get("equipment_type", "")).to_lower():
			_stat_label.text = "Base Defense:"
			_edit_stat.value = int(item_dict.get("base_defense", item_dict.get("base_damage", 0)))
			_preview_info_label.text = "Atlas: armors.png"
		else:
			_stat_label.text = "Base Damage:"
			_edit_stat.value = int(item_dict.get("base_damage", 0))
			_preview_info_label.text = "Atlas: weapons.png"
	elif root_key == "consumables":
		_stat_label.text = "Heal Amount:"
		_edit_stat.value = int(item_dict.get("heal_amount", item_dict.get("heal_percentage", 50)))
		_preview_info_label.text = "Atlas: potions.png"
	else:
		_stat_label.text = "Value:"
		_edit_stat.value = 0
		_preview_info_label.text = "Atlas: potions.png"
	
	var gc = item_dict.get("grid_coordinate", [0, 0])
	if gc is Array and gc.size() >= 2:
		_edit_col_x.value = int(gc[0])
		_edit_row_y.value = int(gc[1])
	elif gc is Dictionary:
		_edit_col_x.value = int(gc.get("column_x", 0))
		_edit_row_y.value = int(gc.get("row_y", 0))
	
	_is_updating_form = false
	_update_preview_texture()


func _on_field_value_changed(_val = null) -> void:
	if _is_updating_form or selected_item_dict.is_empty() or selected_tree_item == null:
		return
	
	var item_id_val = _edit_id.text.strip_edges()
	selected_item_dict["item_id"] = item_id_val
	selected_item_dict["id"] = item_id_val
	selected_item_dict["item_name"] = _edit_name.text.strip_edges()
	
	if selected_root_key == "equipables" or selected_category_name in ["weapons", "armors"]:
		selected_item_dict["equipment_type"] = _edit_type.text.strip_edges().to_upper()
		selected_item_dict["player_class"] = _edit_player_type.text.strip_edges().to_upper()
		selected_item_dict["required_level"] = int(_edit_level.value)
		if selected_category_name == "armors":
			selected_item_dict["base_defense"] = int(_edit_stat.value)
		else:
			selected_item_dict["base_damage"] = int(_edit_stat.value)
	elif selected_root_key == "consumables":
		selected_item_dict["heal_amount"] = int(_edit_stat.value)
		selected_item_dict["potion_type"] = _edit_type.text.strip_edges().to_upper() if not _edit_type.text.is_empty() else "HEALTH"
	
	selected_item_dict["price"] = int(_edit_price.value)
	selected_item_dict["max_stack"] = int(_edit_max_stack.value)
	selected_item_dict["grid_coordinate"] = [int(_edit_col_x.value), int(_edit_row_y.value)]
	selected_item_dict["cell_size"] = [64, 64]
	
	var disp_name = str(selected_item_dict.get("item_name", "Unknown"))
	selected_tree_item.set_text(0, disp_name + " [" + item_id_val + "]")
	
	_update_preview_texture()


func _update_preview_texture() -> void:
	var col_x = int(_edit_col_x.value)
	var row_y = int(_edit_row_y.value)
	
	var atlas_tex = AtlasTexture.new()
	if selected_root_key == "equipables" or selected_category_name in ["weapons", "armors"]:
		if selected_category_name == "armors":
			atlas_tex.atlas = _armors_texture
		else:
			atlas_tex.atlas = _weapons_texture
	else:
		atlas_tex.atlas = _potions_texture
	
	if atlas_tex.atlas != null:
		atlas_tex.region = Rect2(col_x * CELL_SIZE.x, row_y * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
		_preview_rect.texture = atlas_tex
	else:
		_preview_rect.texture = null


func _on_add_category_pressed() -> void:
	_category_name_input.text = ""
	_add_category_dialog.popup_centered()


func _on_add_category_dialog_confirmed() -> void:
	var cat_key = _category_name_input.text.strip_edges().to_lower().replace(" ", "_")
	if cat_key.is_empty():
		_show_status("Category name cannot be empty!", true)
		return
	
	if not current_db_data.has("equipables"):
		current_db_data["equipables"] = {}
	
	var eq_dict: Dictionary = current_db_data["equipables"]
	if eq_dict.has(cat_key):
		_show_status("Category '" + cat_key + "' already exists!", true)
		return
	
	eq_dict[cat_key] = []
	_load_and_populate_db()
	_show_status("Added category '" + cat_key + "' under equipables")


func _on_add_item_pressed() -> void:
	var item = _tree.get_selected()
	if item == null:
		_show_status("Please select a location in the tree to add an item.", true)
		return
	
	var meta = item.get_metadata(0)
	if not meta is Dictionary:
		return
	
	var root_key = meta.get("root_key", "equipables")
	var cat_key = meta.get("cat_key", "weapons")
	
	var target_list: Array = []
	if current_db_data.has(root_key):
		var root_val = current_db_data[root_key]
		if root_val is Dictionary:
			if not root_val.has(cat_key):
				root_val[cat_key] = []
			target_list = root_val[cat_key]
		elif root_val is Array:
			target_list = root_val
	
	var prefix = "w_" if cat_key == "weapons" else ("a_" if cat_key == "armors" else "p_")
	var new_id = prefix + "new_" + str(target_list.size() + 1)
	
	var new_item = {
		"item_id": new_id,
		"item_name": "New Item",
		"price": 50,
		"max_stack": 1,
		"grid_coordinate": [0, 0],
		"cell_size": [64, 64],
		"equipment_type": "SWORD",
		"player_class": "WARRIOR",
		"required_level": 1,
		"base_damage": 10
	}
	
	target_list.append(new_item)
	_load_and_populate_db()
	_show_status("Added new item [" + new_id + "]")


func _on_delete_selected_pressed() -> void:
	var item = _tree.get_selected()
	if item == null:
		return
	
	var meta = item.get_metadata(0)
	if not meta is Dictionary:
		return
	
	var meta_type = meta.get("type", "")
	var root_key = meta.get("root_key", "")
	var cat_key = meta.get("cat_key", "")
	
	if meta_type == "item":
		var item_dict = meta.get("item_dict", {})
		if current_db_data.has(root_key):
			var root_val = current_db_data[root_key]
			if root_val is Dictionary and root_val.has(cat_key):
				root_val[cat_key].erase(item_dict)
			elif root_val is Array:
				root_val.erase(item_dict)
		_load_and_populate_db()
		_show_status("Deleted item.")
	elif meta_type == "category":
		if current_db_data.has(root_key) and current_db_data[root_key] is Dictionary:
			current_db_data[root_key].erase(cat_key)
		_load_and_populate_db()
		_show_status("Deleted category '" + cat_key + "'")


func _on_save_button_pressed() -> void:
	if current_db_data.is_empty():
		_show_status("Cannot save empty database!", true)
		return
	
	var formatted_json = JSON.stringify(current_db_data, "\t")
	
	for path in [DB_PATH, ALT_DB_PATH]:
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(formatted_json)
			file.close()
	
	_show_status("Database successfully saved to " + DB_PATH + "!")


func _show_status(msg: String, is_error: bool = false) -> void:
	if _status_label != null:
		_status_label.text = msg
		if is_error:
			_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		else:
			_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
