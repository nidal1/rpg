## ArcherUnit
## Component encapsulating bow/arrow physics, arrow shooting, and hit detection.
extends Node
class_name ArcherUnit

signal arrow_shot(projectile: Node2D)
signal arrow_hit(target_node: Node2D)

const ARROW_SPRITE_WIDTH: float = 48.0 / 2.2

@export var arrow_scene: PackedScene
@export var attack_range: float = 300.0

var ranged_combatant: RangedCombatant

func _ready() -> void:
	ranged_combatant = RangedCombatant.new()
	add_child(ranged_combatant)

## Spawns and shoots an arrow projectile toward the specified target.
func shoot_arrow(
	owner_combatant: Combatant,
	spawning_node: Node2D,
	container_node: Node2D,
	target_node: Node2D,
	target_group: String
) -> void:
	var scene_to_use = arrow_scene
	if not scene_to_use and "arrow_scene" in owner_combatant:
		scene_to_use = owner_combatant.arrow_scene

	if not scene_to_use:
		push_error("ArcherUnit: arrow_scene is not assigned!")
		return

	var dir = ranged_combatant.calculate_target_direction(owner_combatant, spawning_node, target_node)
	var arrow = scene_to_use.instantiate()
	ranged_combatant.launch_projectile(owner_combatant, arrow, spawning_node, container_node, dir, ARROW_SPRITE_WIDTH, attack_range)

	if arrow.has_signal("arrow_hit"):
		arrow.arrow_hit.connect(func(area: Area2D): _on_arrow_hit(area, owner_combatant, target_group))

	arrow_shot.emit(arrow)

func _on_arrow_hit(area: Area2D, owner_combatant: Combatant, target_group: String) -> void:
	var hit_target = area.get_parent()
	if hit_target and hit_target.is_in_group(target_group):
		hit_target.take_damage(owner_combatant._get_attack_damage())
		arrow_hit.emit(hit_target)
