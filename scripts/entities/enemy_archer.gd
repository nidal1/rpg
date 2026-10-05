extends Enemy
class_name EnemyArcher


# ─── Signals ─────────────────────────────────────────────────────────────────
## Internal signal used by the animation editor to spawn an arrow.
signal _animation_editor_arrow_attack()

# ─── Constants ───────────────────────────────────────────────────────────────
## Offset position for spawning arrows relative to the archer.
const ARROW_POSITION_OFFSET: Vector2 = Vector2(26.0, -51.0)
## Width of the arrow sprite for range calculations.
const ARROW_SPRITE_WIDTH: float = 48.0 / 2.2

# ─── Exported Variables ──────────────────────────────────────────────────────
## The scene to instantiate for the arrow projectile.
@export var arrow_scene: PackedScene

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var arrow_spawning_position: Node2D = $ArrowSpawningPosition
@onready var arrows_container: Node2D = $ArrowsContainer


# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	_animation_editor_arrow_attack.connect(_on_initialized_arrow_attack)


# ─── Private Methods ─────────────────────────────────────────────────────────
## Spawns an arrow projectile.
func _spawn_arrow() -> Arrow:
	var arrow: Arrow = arrow_scene.instantiate()
	arrow.set_as_top_level(true) # Detach the arrow's transform from the archer
	arrow_spawning_position.position = Vector2(ARROW_POSITION_OFFSET.x * last_facing_dir, ARROW_POSITION_OFFSET.y)
	arrows_container.add_child(arrow)
	arrow.global_position = arrow_spawning_position.global_position
	arrow.arrow_hit.connect(_on_arrow_hit)
	arrow.set_max_distance(attack_range - ARROW_POSITION_OFFSET.x - ARROW_SPRITE_WIDTH)
	return arrow

## Moves the spawned arrow in the given direction.
func _move_arrow(arrow: Arrow, _direction: Vector2) -> void:
	arrow.direction = _direction
	arrow.velocity = arrow.direction * arrow.speed


## Called by the animation editor to emit the arrow attack signal.
func _on_animation_editor_arrow_attack() -> void:
	_animation_editor_arrow_attack.emit()

func _on_arrow_hit(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("player"):
		target_node.take_damage(_get_attack_damage())

## Handles the actual spawning and shooting of the arrow.
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
