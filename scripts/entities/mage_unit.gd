## MageUnit
## Component encapsulating water bullet spell casting mechanics and hit detection.
extends Node
class_name MageUnit

signal spell_cast(projectile: Node2D)
signal spell_hit(target_node: Node2D)

const BULLET_SPRITE_WIDTH: float = 32.0 / 2.0

@export var bullet_scene: PackedScene
@export var attack_range: float = 500.0

var ranged_combatant: RangedCombatant

func _ready() -> void:
	ranged_combatant = RangedCombatant.new()
	add_child(ranged_combatant)

## Spawns and casts a water bullet projectile toward the specified target.
func cast_bullet(
	owner_combatant: Combatant,
	spawning_node: Node2D,
	container_node: Node2D,
	target_node: Node2D,
	target_group: String
) -> void:
	var scene_to_use = bullet_scene
	if not scene_to_use and "bullet_scene" in owner_combatant:
		scene_to_use = owner_combatant.bullet_scene

	if not scene_to_use:
		push_error("MageUnit: bullet_scene is not assigned!")
		return

	var dir = ranged_combatant.calculate_target_direction(owner_combatant, spawning_node, target_node)
	var bullet = scene_to_use.instantiate()
	ranged_combatant.launch_projectile(owner_combatant, bullet, spawning_node, container_node, dir, BULLET_SPRITE_WIDTH, attack_range)

	if bullet.has_signal("bullet_hit"):
		bullet.bullet_hit.connect(func(area: Area2D): _on_bullet_hit(area, owner_combatant, target_group))

	spell_cast.emit(bullet)

func _on_bullet_hit(area: Area2D, owner_combatant: Combatant, target_group: String) -> void:
	var hit_target = area.get_parent()
	if hit_target and hit_target.is_in_group(target_group):
		hit_target.take_damage(owner_combatant._get_attack_damage())
		if owner_combatant is Player and hit_target.has_method("get_target") and hit_target.has_method("set_target"):
			if hit_target.get_target() != owner_combatant or not is_instance_valid(hit_target.get_target()):
				hit_target.set_target(owner_combatant)
		spell_hit.emit(hit_target)
