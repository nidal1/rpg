extends Player
class_name Archer

signal _animation_editor_arrow_attack()

@export var arrow_scene: PackedScene
@export var attack_range: float = 300.0

@onready var arrow_spawning_position: Node2D = %ArrowSpawningPosition
@onready var arrows_container: Node2D = %ArrowsContainer

var target: CharacterBody2D = null


func _ready() -> void:
	super._ready()

	_animation_editor_arrow_attack.connect(_on_initialized_arrow_attack)

	animation_tree = $AnimationTree
	animation_playback = animation_tree["parameters/playback"]
	animation_BA_playback = animation_tree["parameters/basic_attack/BasicAttackStateMachine/playback"]
	animation_tree.set_active(true)
	var cls = load("res://resources/classes/archer.tres")
	_load_classe(cls)


## run this function in animation editor at the frame to spawn the arrow
func _on_animation_editor_arrow_attack() -> void:
	_animation_editor_arrow_attack.emit()

# FIXME: flip the sprite to the target direction
func _on_initialized_arrow_attack() -> void:
	var dir = Vector2(last_facing_dir, 0)
	if target:
		dir = arrow_spawning_position.global_position.direction_to(target.get_node("Hurtbox").global_position)
	var arrow = _spawn_arrow()
	arrow.rotation = dir.angle()
	_move_arrow(arrow, dir)


func _spawn_arrow() -> Arrow:
	var arrow: Arrow = arrow_scene.instantiate()
	arrow_spawning_position.position = Vector2(last_facing_dir * 26.0, -51.0)
	arrow.position = arrow_spawning_position.position
	arrows_container.add_child(arrow)
	arrow._on_arrow_hit.connect(_on_arrow_hit)
	return arrow

func _move_arrow(arrow: Arrow, _direction: Vector2) -> void:
	arrow.direction = _direction
	arrow.velocity = arrow.direction * arrow.speed

func _on_arrow_hit(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("enemy"):
		target_node.take_damage(_get_attack_damage())

func _on_state_changed(new_state: DeprecatedState) -> void:
	match new_state:
		DeprecatedState.IDLE: animation_playback.travel(ANIM_IDLE)
		DeprecatedState.RUN: animation_playback.travel(ANIM_RUN)
		DeprecatedState.ATTACKING: animation_playback.travel("basic_attack")

func _play_movement_animation() -> void:
	animation_tree.set("parameters/run/blend_position", last_facing_dir)

func _play_idle_animation() -> void:
	animation_tree.set("parameters/idle/blend_position", last_facing_dir)

func _play_attack_animation(attack: AttackData) -> void:
	animation_tree.set(
	"parameters/basic_attack/BasicAttackStateMachine/%s/blend_position" % attack.anim_name,
	last_facing_dir
	)
	animation_BA_playback.travel(attack.anim_name)


func _end_combo() -> void:
	animation_BA_playback.travel("End")
	super._end_combo()

func _on_hitbox_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("enemy"):
		target_node.take_damage(_get_attack_damage())


func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		target = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		target = null
