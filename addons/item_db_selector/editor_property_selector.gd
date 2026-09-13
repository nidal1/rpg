@tool
extends EditorProperty

const ItemSelectionDialogClass = preload("res://addons/item_db_selector/item_selection_dialog.gd")

var _button: Button
var _dialog: AcceptDialog
var _updating: bool = false


func _init() -> void:
	_button = Button.new()
	_button.text = "Select Items (0 selected)"
	_button.pressed.connect(_on_button_pressed)
	add_child(_button)
	add_focusable(_button)


func _ready() -> void:
	_dialog = ItemSelectionDialogClass.new()
	add_child(_dialog)
	if not _dialog.items_selected.is_connected(_on_items_selected):
		_dialog.items_selected.connect(_on_items_selected)


func _update_property() -> void:
	if _updating:
		return
	
	var current_val = get_edited_object()[get_edited_property()]
	var count = 0
	if current_val is Array:
		count = current_val.size()
	
	if _button != null:
		_button.text = "Select Items (" + str(count) + " selected)"


func _on_button_pressed() -> void:
	var current_val = get_edited_object()[get_edited_property()]
	var selected_ids: Array[String] = []
	if current_val is Array:
		for item in current_val:
			selected_ids.append(str(item))
	
	if _dialog != null:
		_dialog.set_selected_ids(selected_ids)
		_dialog.popup_centered_ratio(0.6)


func _on_items_selected(new_items: Array[Dictionary]) -> void:
	_updating = true
	emit_changed(get_edited_property(), new_items)
	if _button != null:
		_button.text = "Select Items (" + str(new_items.size()) + " selected)"
	_updating = false
