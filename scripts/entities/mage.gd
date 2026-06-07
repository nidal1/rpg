## Mage
## A ranged player class that casts water bullet spells at enemies.
extends Player
class_name Mage

# ─── Signals ─────────────────────────────────────────────────────────────────
## Internal signal used by the animation editor to spawn a bullet.
signal _animation_editor_bullet_attack()

# ─── Constants ───────────────────────────────────────────────────────────────
## Offset position for spawning bullets relative to the mage.
const BULLET_POSITION_OFFSET: Vector2 = Vector2(26.0, -51.0)
## Width of the bullet sprite for range calculations.
const BULLET_SPRITE_WIDTH: float = 32.0 / 2.0

# ─── Exported Variables ──────────────────────────────────────────────────────
## The scene to instantiate for the water bullet projectile.
@export var bullet_scene: PackedScene
## The maximum attack range of the mage.
@export var attack_range: float = 500.0

# ─── Public Variables ────────────────────────────────────────────────────────
## The current targeted enemy.
var target: CharacterBody2D = null
## List of enemies currently within detection range.
var enemies_in_range: Array[CharacterBody2D] = []

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var bullet_spawning_position: Node2D = %BulletSpawningPosition
@onready var bullets_container: Node2D = %BulletsContainer
@onready var detection_zone: Area2D = $DetectionZone

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	detection_zone.get_node("CollisionShape2D").shape.radius = attack_range
	_animation_editor_bullet_attack.connect(_on_initialized_bullet_attack)
	var cls = load("res://resources/classes/mage.tres")
	_load_classe(cls)

# ─── Private Methods ─────────────────────────────────────────────────────────
## Spawns a water bullet projectile.
func _spawn_bullet() -> WaterBullet:
	var bullet: WaterBullet = bullet_scene.instantiate()
	bullet.set_as_top_level(true) # Detach the bullet's transform from the mage
	bullet_spawning_position.position = Vector2(BULLET_POSITION_OFFSET.x * last_facing_dir, BULLET_POSITION_OFFSET.y)
	bullets_container.add_child(bullet)
	bullet.global_position = bullet_spawning_position.global_position
	bullet.bullet_hit.connect(_on_bullet_hit)
	bullet.set_max_distance(attack_range - BULLET_POSITION_OFFSET.x - BULLET_SPRITE_WIDTH)
	return bullet

## Moves the spawned bullet in the given direction.
func _move_bullet(bullet: WaterBullet, _direction: Vector2) -> void:
	bullet.direction = _direction
	bullet.velocity = bullet.direction * bullet.speed

## Updates the current target based on enemies in range.
func _update_target() -> void:
	target = null
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			target = enemy
			break

# ─── Signal Handlers ─────────────────────────────────────────────────────────
## Called by the animation editor to emit the bullet attack signal.
func _on_animation_editor_bullet_attack() -> void:
	_animation_editor_bullet_attack.emit()

## Handles the actual spawning and casting of the bullet.
func _on_initialized_bullet_attack() -> void:
	var dir = Vector2(last_facing_dir, 0)
	if target and is_instance_valid(target):
		var target_pos = target.global_position
		if target.has_node("Hurtbox"):
			target_pos = target.get_node("Hurtbox").global_position
			
		dir = bullet_spawning_position.global_position.direction_to(target_pos)
		
		if sign(dir.x) != 0:
			last_facing_dir = sign(dir.x)
			
	var bullet = _spawn_bullet()
	bullet.rotation = dir.angle()
	_move_bullet(bullet, dir)

func _on_bullet_hit(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("enemy"):
		target_node.take_damage(_get_attack_damage())
		if target_node.get_target() != self or not is_instance_valid(target_node.get_target()):
			target_node.set_target(self)

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if not body in enemies_in_range:
			enemies_in_range.append(body)
		_update_target()

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)
		_update_target()
