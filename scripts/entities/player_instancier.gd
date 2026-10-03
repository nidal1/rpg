@tool
extends Node2D
class_name PlayerInstancier
@onready var player_camera: Camera2D = $PlayerCamera

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
		player_instance.position = target_pos
		
		add_child(player_instance)
		player_instance.global_position = target_pos
		player_instance.force_update_transform()

func _physics_process(delta: float) -> void:
	if player_instance:
		player_camera.global_position = player_instance.global_position
