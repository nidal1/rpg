## Archer
## A ranged player class extending Player, using ArcherUnit composition for shooting arrows.
extends Player
class_name Archer

# ─── Signals ─────────────────────────────────────────────────────────────────
signal _animation_editor_arrow_attack()

# ─── Exported Variables ──────────────────────────────────────────────────────
@export var arrow_scene: PackedScene


# ─── Public Variables ────────────────────────────────────────────────────────
var enemies_in_range: Array[CharacterBody2D] = []

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var arrow_spawning_position: Node2D = %ArrowSpawningPosition
@onready var arrows_container: Node2D = %ArrowsContainer
@onready var archer_unit: ArcherUnit = $ArcherUnit if has_node("ArcherUnit") else _get_or_create_archer_unit()
@onready var detection_zone: Area2D = $DetectionZone

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	_animation_editor_arrow_attack.connect(_on_initialized_arrow_attack)
	var cls = load("res://resources/classes/archer.tres")
	attack_range = cls.attack_range
	detection_zone.get_node("CollisionShape2D").shape.radius = attack_range
	_load_classe(cls)

# ─── Private Methods ─────────────────────────────────────────────────────────
func _get_or_create_archer_unit() -> ArcherUnit:
	var unit = ArcherUnit.new()
	unit.name = "ArcherUnit"
	unit.arrow_scene = arrow_scene
	unit.attack_range = attack_range
	add_child(unit)
	return unit

func _update_target() -> void:
	target = null
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			target = enemy
			break

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_animation_editor_arrow_attack() -> void:
	_animation_editor_arrow_attack.emit()

func _on_initialized_arrow_attack() -> void:
	if archer_unit:
		archer_unit.arrow_scene = arrow_scene
		archer_unit.attack_range = attack_range
		archer_unit.shoot_arrow(self, arrow_spawning_position, arrows_container, target, "enemy")

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if not body in enemies_in_range:
			enemies_in_range.append(body)
		_update_target()

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)
		_update_target()
