## EnemyArcher
## Ranged enemy entity extending Enemy, using ArcherUnit composition for shooting arrows.
extends Enemy
class_name EnemyArcher

# ─── Signals ─────────────────────────────────────────────────────────────────
signal _animation_editor_arrow_attack()

# ─── Exported Variables ──────────────────────────────────────────────────────
@export var arrow_scene: PackedScene

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var arrow_spawning_position: Node2D = $ArrowSpawningPosition
@onready var arrows_container: Node2D = $ArrowsContainer
@onready var archer_unit: ArcherUnit = $ArcherUnit if has_node("ArcherUnit") else _get_or_create_archer_unit()

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	_animation_editor_arrow_attack.connect(_on_initialized_arrow_attack)

# ─── Private Methods ─────────────────────────────────────────────────────────
func _get_or_create_archer_unit() -> ArcherUnit:
	var unit = ArcherUnit.new()
	unit.name = "ArcherUnit"
	unit.arrow_scene = arrow_scene
	unit.attack_range = attack_range
	add_child(unit)
	return unit

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_animation_editor_arrow_attack() -> void:
	_animation_editor_arrow_attack.emit()

func _on_initialized_arrow_attack() -> void:
	if archer_unit:
		archer_unit.arrow_scene = arrow_scene
		archer_unit.attack_range = attack_range
		archer_unit.shoot_arrow(self, arrow_spawning_position, arrows_container, target, "player")
