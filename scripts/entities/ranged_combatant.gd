## RangedCombatant
## Component encapsulating shared ranged combat math, trajectory calculation, and projectile launching.
extends Node
class_name RangedCombatant

# ─── Constants ───────────────────────────────────────────────────────────────
const PROJECTILE_POSITION_OFFSET: Vector2 = Vector2(26.0, -51.0)

# ─── Exported Variables ──────────────────────────────────────────────────────
@export var attack_range: float = 300.0

# ─── Public Methods ──────────────────────────────────────────────────────────
## Calculates the normalized direction vector toward the target (accounting for Hurtbox).
## Automatically updates last_facing_dir of the owner combatant.
func calculate_target_direction(owner_combatant: Combatant, spawning_node: Node2D, target_node: Node2D) -> Vector2:
	var dir := Vector2(owner_combatant.last_facing_dir if owner_combatant else 1.0, 0.0)
	if is_instance_valid(target_node):
		var target_pos := target_node.global_position
		if target_node.has_node("Hurtbox"):
			target_pos = target_node.get_node("Hurtbox").global_position
		dir = spawning_node.global_position.direction_to(target_pos)

	if owner_combatant and sign(dir.x) != 0:
		owner_combatant.last_facing_dir = sign(dir.x)

	return dir

## Launches a projectile by setting up top-level transform, rotation, velocity, and range.
func launch_projectile(
	owner_combatant: Combatant,
	projectile: Node2D,
	spawning_node: Node2D,
	container_node: Node2D,
	dir: Vector2,
	sprite_width: float,
	custom_range: float = -1.0
) -> void:
	var effective_range = custom_range if custom_range > 0.0 else attack_range
	var facing_dir = owner_combatant.last_facing_dir if owner_combatant else 1.0
	
	projectile.set_as_top_level(true)
	spawning_node.position = Vector2(PROJECTILE_POSITION_OFFSET.x * facing_dir, PROJECTILE_POSITION_OFFSET.y)
	container_node.add_child(projectile)
	
	projectile.global_position = spawning_node.global_position
	projectile.rotation = dir.angle()
	
	projectile.direction = dir
	projectile.velocity = dir * projectile.speed
	if projectile.has_method("set_max_distance"):
		projectile.set_max_distance(effective_range - PROJECTILE_POSITION_OFFSET.x - sprite_width)
