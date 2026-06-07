extends Node


signal initialize_hero_stats_ui(cls: CharacterClass)
signal update_hero_avatar_texture(texture: Texture2D)
signal update_hp_bar_value(value: float)
signal update_mana_bar_value(value: float)


signal enemy_died(enemy: Enemy)
signal enemy_spawned(enemy: Enemy, spawn_position: Vector2)
signal xp_changed(current: int)
signal level_up(new_level: int)

signal stat_allocated(stat_name: String)
signal stat_deallocated(stat_name: String)

signal stats_updated()
signal save_stats_points()
signal cancel_stats_points()

signal lootable_item_added(item: Item)
signal lootable_item_removed(item: Item)
signal display_lootable_item_hover_info(item: Item)
signal hide_lootable_item_hover_info(item: Item)

signal selected_lootable_items_picked_up(slots: Array[Item])
