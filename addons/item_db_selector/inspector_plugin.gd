@tool
extends EditorInspectorPlugin

const EditorPropertySelector = preload("res://addons/item_db_selector/editor_property_selector.gd")


func _can_handle(object: Object) -> bool:
	# Handles any inspected object in Godot editor
	return true


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name == "custom_db_item_objects":
		var property_editor = EditorPropertySelector.new()
		add_property_editor(name, property_editor)
		# Return true to remove default inspector control for selected_item_ids
		return true
	return false
