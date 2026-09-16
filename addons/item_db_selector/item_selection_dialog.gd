@tool
extends AcceptDialog

## Signal emitted when the user confirms their item selection.
signal items_selected(selected_items: Array[Dictionary])

const DB_PATH = "res://data/items_data.json"
const WEAPONS_ATLAS_PATH = "res://assets/sprites/items/weapons.png"
const ARMORS_ATLAS_PATH = "res://assets/sprites/items/armors.png"
const CELL_SIZE = Vector2i(64, 64)

var _selected_ids: Array[String] = []
var _item_checkboxes: Dictionary = {} # item_id (String) -> CheckBox
var _item_containers: Dictionary = {} # item_id (String) -> Control
var _item_data_map: Dictionary = {} # item_id (String) -> Dictionary

var _weapons_texture: Texture2D
var _armors_texture: Texture2D

var _search_edit: LineEdit
var _tab_container: TabContainer
var _status_label: Label
var _is_initialized: bool = false
var _sort_option_button: OptionButton
var _sort_mode: String = "default" # "default", "price_asc", "price_desc", "level_asc", "level_desc"

func _init() -> void:
	title = "Select Item IDs from Database"
	size = Vector2i(800, 600)
	min_size = Vector2i(650, 500)
	exclusive = true
	
	if not confirmed.is_connected(_on_confirmed):
		confirmed.connect(_on_confirmed)


func _ready() -> void:
	if not _is_initialized:
		_build_ui()
		_is_initialized = true


func set_selected_ids(ids: Array) -> void:
	_selected_ids.clear()
	for id in ids:
		_selected_ids.append(str(id))
	_update_checkbox_states()
	_update_status_label()


func _update_checkbox_states() -> void:
	for item_id in _item_checkboxes:
		var cb: CheckBox = _item_checkboxes[item_id]
		if is_instance_valid(cb):
			cb.button_pressed = (item_id in _selected_ids)


func _build_ui() -> void:
	# Clear existing children if any
	for child in get_children():
		child.queue_free()
	
	_load_textures()
	var db = _load_database()
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)
	
	# Top Search & Action Bar
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	main_vbox.add_child(top_bar)
	
	var search_label = Label.new()
	search_label.text = "Search:"
	top_bar.add_child(search_label)
	
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Filter by name, id, or type..."
	_search_edit.clear_button_enabled = true
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.text_changed.connect(_on_search_text_changed)
	top_bar.add_child(_search_edit)
	
	var btn_select_all = Button.new()
	btn_select_all.text = "Select Visible"
	btn_select_all.pressed.connect(_on_select_visible_pressed)
	top_bar.add_child(btn_select_all)
	
	var btn_deselect_all = Button.new()
	btn_deselect_all.text = "Deselect Visible"
	btn_deselect_all.pressed.connect(_on_deselect_visible_pressed)
	top_bar.add_child(btn_deselect_all)
	
	var btn_clear_all = Button.new()
	btn_clear_all.text = "Clear All"
	btn_clear_all.pressed.connect(_on_clear_all_pressed)
	top_bar.add_child(btn_clear_all)

	var sort_label = Label.new()
	sort_label.text = "Sort:"
	top_bar.add_child(sort_label)

	_sort_option_button = OptionButton.new()
	_sort_option_button.add_item("Default", 0)
	_sort_option_button.add_item("Price: Low to High", 1)
	_sort_option_button.add_item("Price: High to Low", 2)
	_sort_option_button.add_item("Level: Low to High", 3)
	_sort_option_button.add_item("Level: High to Low", 4)
	_sort_option_button.item_selected.connect(_on_sort_option_selected)
	top_bar.add_child(_sort_option_button)
	
	# Tab Container for Root Databases
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_tab_container)
	
	_item_checkboxes.clear()
	_item_containers.clear()
	_item_data_map.clear()
	
	# Populate Weapons Tab
	if db.has("weapons_database"):
		_create_database_tab("Weapons", db["weapons_database"], _weapons_texture)
	
	# Populate Armors Tab
	if db.has("armors_database"):
		_create_database_tab("Armors", db["armors_database"], _armors_texture)
	
	# Bottom Status Bar
	var bottom_bar = HBoxContainer.new()
	main_vbox.add_child(bottom_bar)
	
	_status_label = Label.new()
	_status_label.text = "0 items selected"
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	bottom_bar.add_child(_status_label)


func _load_textures() -> void:
	if ResourceLoader.exists(WEAPONS_ATLAS_PATH):
		_weapons_texture = load(WEAPONS_ATLAS_PATH)
	if ResourceLoader.exists(ARMORS_ATLAS_PATH):
		_armors_texture = load(ARMORS_ATLAS_PATH)


func _load_database() -> Dictionary:
	if not FileAccess.file_exists(DB_PATH):
		push_error("ItemDBSelector: Database file missing at " + DB_PATH)
		return {}
	var file = FileAccess.open(DB_PATH, FileAccess.READ)
	if not file:
		push_error("ItemDBSelector: Cannot open database file at " + DB_PATH)
		return {}
	var json_str = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		push_error("ItemDBSelector: JSON Parse Error: " + json.get_error_message())
		return {}
	return json.get_data()


func _create_database_tab(tab_title: String, db_root: Dictionary, atlas_tex: Texture2D) -> void:
	var scroll = ScrollContainer.new()
	scroll.name = tab_title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_container.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(content_vbox)
	
	for category_name in db_root:
		var items_list = db_root[category_name]
		if not items_list is Array:
			continue
		
		# Nsskh l-list bach ma-n-beddloch l-original JSON array f-memory
		var sorted_items = items_list.duplicate()
		_sort_item_list(sorted_items)
		
		# Category Container
		var cat_vbox = VBoxContainer.new()
		cat_vbox.name = "Cat_" + str(category_name)
		content_vbox.add_child(cat_vbox)
		
		# Category Header
		var cat_header = Label.new()
		var formatted_cat = category_name.capitalize().replace("_", " ")
		cat_header.text = "--- " + formatted_cat + " ---"
		cat_header.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		cat_header.add_theme_font_size_override("font_size", 14)
		cat_vbox.add_child(cat_header)
		
		# Grid Container for items
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cat_vbox.add_child(grid)
		
		for item in sorted_items:
			if not item is Dictionary or not item.has("id"):
				continue
			var item_card = _create_item_card(item, atlas_tex)
			grid.add_child(item_card)

func _create_item_card(item: Dictionary, atlas_tex: Texture2D) -> Control:
	var item_id: String = str(item.get("id", ""))
	var item_name: String = str(item.get("name", "Unknown Item"))
	var item_type: String = str(item.get("type", "Item"))
	var req_level: int = int(item.get("required_level", 1))
	var grid_coord: Dictionary = item.get("grid_coordinate", {"column_x": 0, "row_y": 0})
	var col_x: int = int(grid_coord.get("column_x", 0))
	var row_y: int = int(grid_coord.get("row_y", 0))
	
	_item_data_map[item_id] = item
	
	# Main Box Card
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	
	# Cropped Atlas Texture Icon Preview
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(48, 48)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if atlas_tex != null:
		var atlas_sub = AtlasTexture.new()
		atlas_sub.atlas = atlas_tex
		atlas_sub.region = Rect2(col_x * CELL_SIZE.x, row_y * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
		tex_rect.texture = atlas_sub
	hbox.add_child(tex_rect)
	
	# Right info column
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(info_vbox)
	
	var checkbox = CheckBox.new()
	checkbox.text = item_name + " [" + item_id + "]"
	checkbox.toggled.connect(func(pressed: bool): _on_checkbox_toggled(item_id, pressed))
	info_vbox.add_child(checkbox)
	
	var item_price: int = int(item.get("price", 0))

	var meta_label = Label.new()
	meta_label.text = "Type: " + item_type + " | Req. Lvl: " + str(req_level) + " | Price: " + str(item_price) + "g"
	meta_label.add_theme_font_size_override("font_size", 11)
	meta_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(meta_label)
	
	_item_checkboxes[item_id] = checkbox
	_item_containers[item_id] = panel
	
	return panel

func _sort_item_list(items: Array) -> void:
	match _sort_mode:
		"price_asc":
			items.sort_custom(func(a, b): return int(a.get("price", 0)) < int(b.get("price", 0)))
		"price_desc":
			items.sort_custom(func(a, b): return int(a.get("price", 0)) > int(b.get("price", 0)))
		"level_asc":
			items.sort_custom(func(a, b): return int(a.get("required_level", 1)) < int(b.get("required_level", 1)))
		"level_desc":
			items.sort_custom(func(a, b): return int(a.get("required_level", 1)) > int(b.get("required_level", 1)))
		_:
			pass # Default array order from JSON

func _on_checkbox_toggled(item_id: String, pressed: bool) -> void:
	if pressed:
		if not item_id in _selected_ids:
			_selected_ids.append(item_id)
	else:
		_selected_ids.erase(item_id)
	_update_status_label()


func _update_status_label() -> void:
	if _status_label != null:
		_status_label.text = str(_selected_ids.size()) + " items selected"


func _on_search_text_changed(new_text: String) -> void:
	var query = new_text.strip_edges().to_lower()
	
	for item_id in _item_containers:
		var card: Control = _item_containers[item_id]
		var item: Dictionary = _item_data_map.get(item_id, {})
		var item_name: String = str(item.get("name", "")).to_lower()
		var item_type: String = str(item.get("type", "")).to_lower()
		var id_lower: String = item_id.to_lower()
		
		var matches = query.is_empty() or (query in item_name) or (query in id_lower) or (query in item_type)
		card.visible = matches


func _on_select_visible_pressed() -> void:
	for item_id in _item_containers:
		var card: Control = _item_containers[item_id]
		if card.visible and _item_checkboxes.has(item_id):
			var cb: CheckBox = _item_checkboxes[item_id]
			cb.button_pressed = true


func _on_deselect_visible_pressed() -> void:
	for item_id in _item_containers:
		var card: Control = _item_containers[item_id]
		if card.visible and _item_checkboxes.has(item_id):
			var cb: CheckBox = _item_checkboxes[item_id]
			cb.button_pressed = false


func _on_clear_all_pressed() -> void:
	for item_id in _item_checkboxes:
		var cb: CheckBox = _item_checkboxes[item_id]
		cb.button_pressed = false


func _on_confirmed() -> void:
	var result: Array[Dictionary] = []
	for id in _selected_ids:
		if _item_data_map.has(id):
			result.append(_item_data_map[id])
	items_selected.emit(result)

func _on_sort_option_selected(index: int) -> void:
	match index:
		0: _sort_mode = "default"
		1: _sort_mode = "price_asc"
		2: _sort_mode = "price_desc"
		3: _sort_mode = "level_asc"
		4: _sort_mode = "level_desc"
	
	# Save active tab index and re-build UI to apply sorting
	var active_tab = _tab_container.current_tab if _tab_container != null else 0
	_build_ui()
	_update_checkbox_states()
	_update_status_label()
	if _tab_container != null and active_tab < _tab_container.get_tab_count():
		_tab_container.current_tab = active_tab