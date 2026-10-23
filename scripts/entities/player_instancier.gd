@tool
extends Node2D
class_name PlayerInstancier
@onready var player_camera: Camera2D = $PlayerCamera

@export var camera_zoom_speed: float = 0.1
@export var selected_player: CharacterClass.PlayerType = CharacterClass.PlayerType.WARRIOR
@export var use_default_position: bool = true:
	set(value):
		use_default_position = value
		notify_property_list_changed()

@export var instance_position: Vector2 = Vector2.ZERO

@export_group("Player Scenes")
@export var warrior_scene: PackedScene
@export var archer_scene: PackedScene
@export var mage_scene: PackedScene

var player_instance: Player = null
var old_camera_position: Vector2 = Vector2.ZERO
var is_camera_in_player_position: bool = false
var camera_zoom_off = Vector2.ONE

func _validate_property(property: Dictionary) -> void:
	if property.name == "instance_position":
		if use_default_position:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		else:
			property.usage = PROPERTY_USAGE_DEFAULT


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	match selected_player:
		CharacterClass.PlayerType.WARRIOR:
			if warrior_scene: player_instance = warrior_scene.instantiate()
		CharacterClass.PlayerType.ARCHER:
			if archer_scene: player_instance = archer_scene.instantiate()
		CharacterClass.PlayerType.MAGE:
			if mage_scene: player_instance = mage_scene.instantiate()

	if player_instance:
		var target_pos: Vector2 = global_position if use_default_position else instance_position
		
		add_child(player_instance)
		player_instance.global_position = target_pos
		is_camera_in_player_position = player_instance.global_position.is_equal_approx(old_camera_position)
		player_instance.force_update_transform()
		player_camera.global_position = player_instance.global_position
		
		player_camera.zoom = camera_zoom_off
		old_camera_position = player_camera.global_position


func _physics_process(delta: float) -> void:
	if player_instance and not is_camera_in_player_position:
		player_camera.global_position = player_instance.global_position
		old_camera_position = player_camera.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		camera_zoom_off.x = clamp(camera_zoom_off.x - camera_zoom_speed, 0.5, 1)
		camera_zoom_off.y = clamp(camera_zoom_off.y - camera_zoom_speed, 0.5, 1)
		player_camera.zoom = camera_zoom_off
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		camera_zoom_off.x = clamp(camera_zoom_off.x + camera_zoom_speed, 0.5, 1)
		camera_zoom_off.y = clamp(camera_zoom_off.y + camera_zoom_speed, 0.5, 1)
		player_camera.zoom = camera_zoom_off
