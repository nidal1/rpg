## Mage
## A ranged player class extending Player, using MageUnit composition for spellcasting.
extends Player
class_name Mage

# ─── Signals ─────────────────────────────────────────────────────────────────
signal _animation_editor_bullet_attack()

# ─── Exported Variables ──────────────────────────────────────────────────────
@export var bullet_scene: PackedScene
@export var attack_range: float = 500.0

# ─── Public Variables ────────────────────────────────────────────────────────
var target: CharacterBody2D = null
var enemies_in_range: Array[CharacterBody2D] = []

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var bullet_spawning_position: Node2D = %BulletSpawningPosition
@onready var bullets_container: Node2D = %BulletsContainer
@onready var detection_zone: Area2D = $DetectionZone
@onready var mage_unit: MageUnit = $MageUnit if has_node("MageUnit") else _get_or_create_mage_unit()

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	detection_zone.get_node("CollisionShape2D").shape.radius = attack_range
	_animation_editor_bullet_attack.connect(_on_initialized_bullet_attack)
	var cls = load("res://resources/classes/mage.tres")
	_load_classe(cls)

# ─── Private Methods ─────────────────────────────────────────────────────────
func _get_or_create_mage_unit() -> MageUnit:
	var unit = MageUnit.new()
	unit.name = "MageUnit"
	unit.bullet_scene = bullet_scene
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
func _on_animation_editor_bullet_attack() -> void:
	_animation_editor_bullet_attack.emit()

func _on_initialized_bullet_attack() -> void:
	if mage_unit:
		mage_unit.bullet_scene = bullet_scene
		mage_unit.attack_range = attack_range
		mage_unit.cast_bullet(self, bullet_spawning_position, bullets_container, target, "enemy")

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if not body in enemies_in_range:
			enemies_in_range.append(body)
		_update_target()

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)
		_update_target()
