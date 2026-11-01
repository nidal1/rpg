## Mage
## A ranged player class extending Player, using MageUnit composition for spellcasting.
extends Player
class_name Mage

# ─── Signals ─────────────────────────────────────────────────────────────────
signal _animation_editor_bullet_attack()

# ─── Exported Variables ──────────────────────────────────────────────────────
@export var bullet_scene: PackedScene


# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var bullet_spawning_position: Node2D = %BulletSpawningPosition
@onready var bullets_container: Node2D = %BulletsContainer
@onready var mage_unit: MageUnit = $MageUnit if has_node("MageUnit") else _get_or_create_mage_unit()

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	_animation_editor_bullet_attack.connect(_on_initialized_bullet_attack)
	var cls = load("res://resources/classes/mage.tres")
	attack_range = cls.attack_range
	detection_zone.get_node("CollisionShape2D").shape.radius = attack_range
	_load_classe(cls)

# ─── Private Methods ─────────────────────────────────────────────────────────
func _get_or_create_mage_unit() -> MageUnit:
	var unit = MageUnit.new()
	unit.name = "MageUnit"
	unit.bullet_scene = bullet_scene
	unit.attack_range = attack_range
	add_child(unit)
	return unit

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_animation_editor_bullet_attack() -> void:

	_animation_editor_bullet_attack.emit()

func _on_initialized_bullet_attack() -> void:
	if mage_unit:
		mage_unit.bullet_scene = bullet_scene
		mage_unit.attack_range = attack_range
		mage_unit.cast_bullet(self, bullet_spawning_position, bullets_container, target, "enemy")
