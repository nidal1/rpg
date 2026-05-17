extends Player
class_name Archer

signal _animation_editor_arrow_attack()

@export var arrow_scene: PackedScene
@export var attack_range: float = 300.0

@onready var arrow_spawning_position: Node2D = %ArrowSpawningPosition
@onready var arrows_container: Node2D = %ArrowsContainer

var target: CharacterBody2D = null
var enemies_in_range: Array[CharacterBody2D] = []

const ARROW_POSITION_OFFSET: Vector2 = Vector2(26.0, -51.0)
const ARROW_SPRITE_WIDTH: float = 48.0 / 2.2

func _ready() -> void:
	super._ready()

	_animation_editor_arrow_attack.connect(_on_initialized_arrow_attack)
	var cls = load("res://resources/classes/archer.tres")
	_load_classe(cls)


## run this function in animation editor at the frame to spawn the arrow
func _on_animation_editor_arrow_attack() -> void:
	_animation_editor_arrow_attack.emit()

func _on_initialized_arrow_attack() -> void:
	var dir = Vector2(last_facing_dir, 0)
	if target and is_instance_valid(target):
		var target_pos = target.global_position
		if target.has_node("Hurtbox"):
			target_pos = target.get_node("Hurtbox").global_position
			
		dir = arrow_spawning_position.global_position.direction_to(target_pos)
		
		if sign(dir.x) != 0:
			last_facing_dir = sign(dir.x)
			
	var arrow = _spawn_arrow()
	arrow.rotation = dir.angle()
	_move_arrow(arrow, dir)


func _spawn_arrow() -> Arrow:
	var arrow: Arrow = arrow_scene.instantiate()
	arrow.set_as_top_level(true) # Detach the arrow's transform from the archer
	arrow_spawning_position.position = Vector2(ARROW_POSITION_OFFSET.x * last_facing_dir, ARROW_POSITION_OFFSET.y)
	arrows_container.add_child(arrow)
	arrow.global_position = arrow_spawning_position.global_position
	arrow.arrow_hit.connect(_on_arrow_hit)
	arrow.set_max_distance(attack_range - ARROW_POSITION_OFFSET.x - ARROW_SPRITE_WIDTH)
	return arrow

func _move_arrow(arrow: Arrow, _direction: Vector2) -> void:
	arrow.direction = _direction
	arrow.velocity = arrow.direction * arrow.speed

func _on_arrow_hit(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("enemy"):
		target_node.take_damage(_get_attack_damage())



func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if not body in enemies_in_range:
			enemies_in_range.append(body)
		_update_target()


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)
		_update_target()

func _update_target() -> void:
	target = null
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			target = enemy
			break
