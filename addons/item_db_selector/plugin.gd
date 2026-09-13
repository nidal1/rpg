@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/item_db_selector/inspector_plugin.gd")
const ItemManagerPanelClass = preload("res://addons/item_db_selector/item_manager_panel.gd")

var _inspector_plugin: EditorInspectorPlugin
var _main_panel_instance: Control


func _enter_tree() -> void:
	# Register Inspector Property Plugin
	_inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(_inspector_plugin)
	
	# Register Main Screen Tab Panel
	_main_panel_instance = ItemManagerPanelClass.new()
	_main_panel_instance.name = "Item DB Manager"
	get_editor_interface().get_editor_main_screen().add_child(_main_panel_instance)
	_make_visible(false)


func _exit_tree() -> void:
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null
	
	if _main_panel_instance != null:
		_main_panel_instance.queue_free()
		_main_panel_instance = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _main_panel_instance != null:
		_main_panel_instance.visible = visible


func _get_plugin_name() -> String:
	return "Item DB Manager"


func _get_plugin_icon() -> Texture2D:
	if get_editor_interface() != null:
		var base_control = get_editor_interface().get_base_control()
		if base_control != null and base_control.has_theme_icon("Object", "EditorIcons"):
			return base_control.get_theme_icon("Object", "EditorIcons")
	return null
