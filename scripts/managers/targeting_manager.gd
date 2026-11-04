## TargetingManager
## Manages enemy selection, ground targeting, and selection box visuals.
class_name TargetingManager
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
const ENEMY_HURTBOX_LAYER: int = 1 << 6

# ─── Public Variables ────────────────────────────────────────────────────────
var selection_box_scene: PackedScene = load("res://scenes/ui/selection_box.tscn")
var is_enemy_selected: bool = false
var selected_enemy: Enemy = null

# ─── Public Methods ──────────────────────────────────────────────────────────
## Handles mouse click targeting (enemy or ground).
func handle_mouse_targeting(mouse_pos: Vector2, viewport: Viewport, player: Player) -> void:
	var enemy = get_enemy_at_position(mouse_pos, viewport)

	if enemy:
		select_enemy(enemy, player)
	else:
		select_ground_position(mouse_pos, player)

## Selects an enemy as the current target.
func select_enemy(enemy: Enemy, player: Player) -> void:
	clear_all_selection_boxes()

	if selected_enemy:
		clear_selection(player)

	selected_enemy = enemy
	is_enemy_selected = true

	if player:
		player.set_enemy_target(enemy)

	EventBus.enemy_selected.emit(enemy)

## Selects a ground position as movement target.
func select_ground_position(pos: Vector2, player: Player) -> void:
	if selected_enemy:
		clear_selection(player)

	create_selection_box_at(pos)

	if player:
		player.set_ground_target(pos)

## Clears current selection.
func clear_selection(player: Player) -> void:
	is_enemy_selected = false

	if player:
		player.clear_target()

	EventBus.enemy_unselected.emit(selected_enemy)
	selected_enemy = null

## Gets the currently selected enemy.
func get_selected_enemy() -> Enemy:
	return selected_enemy

## Checks if an enemy is currently selected.
func is_enemy_currently_selected() -> bool:
	return is_enemy_selected

## Physics query to find enemy at screen position.
func get_enemy_at_position(pos: Vector2, viewport: Viewport) -> Node2D:
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = ENEMY_HURTBOX_LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var space = viewport.world_2d.direct_space_state
	var results = space.intersect_point(query)

	for result in results:
		var collider = result.collider
		var enemy = collider.get_parent()

		if enemy and enemy.is_in_group("enemy"):
			return enemy

	return null

## Creates a selection box visual at position.
func create_selection_box_at(pos: Vector2) -> void:
	clear_all_selection_boxes()

	var selection_box_instance = selection_box_scene.instantiate()
	get_node("/root/World/SelectionBoxes").add_child(selection_box_instance)
	selection_box_instance.global_position = pos

## Clears all active selection boxes.
func clear_all_selection_boxes() -> void:
	var selection_boxes_container = get_node("/root/World/SelectionBoxes")
	if selection_boxes_container.get_children().size():
		for child in selection_boxes_container.get_children():
			child.queue_free()

## Gets the first active selection box (if any).
func get_active_selection_box() -> Node:
	var selection_boxes_container = get_node("/root/World/SelectionBoxes")
	var children = selection_boxes_container.get_children()
	if children.size():
		return children[0]
	return null
