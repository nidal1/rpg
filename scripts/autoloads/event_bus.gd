## EventBus
## Manages global signals and events for the game, acting as a central hub
## for communication between disparate systems.
extends Node

# ─── UI & HUD Signals ────────────────────────────────────────────────────────
## Emitted to initialize the hero stats UI.
signal initialize_hero_stats_ui(cls: CharacterClass)
## Emitted when the hero's avatar texture is updated.
signal update_hero_avatar_texture(texture: Texture2D)
## Emitted to update the HP bar UI value.
signal update_hp_bar_value(value: float)
## Emitted to update the Mana bar UI value.
signal update_mana_bar_value(value: float)

# ─── Game & Combat Signals ───────────────────────────────────────────────────
## Emitted when an enemy dies.
signal enemy_died(enemy: Enemy)
## Emitted when an enemy spawns at a specific position.
signal enemy_spawned(enemy: Enemy, spawn_position: Vector2)
## Emitted when the player's experience points change.
signal xp_changed(current: int)
## Emitted when the player levels up.
signal level_up(new_level: int)

# ─── Stats Allocation Signals ────────────────────────────────────────────────
## Emitted when a stat point is allocated.
signal stat_allocated(stat_name: String)
## Emitted when a stat point is deallocated.
signal stat_deallocated(stat_name: String)
## Emitted when stats are updated in the UI.
signal stats_updated()
## Emitted to save the current stat points allocation.
signal save_stats_points()
## Emitted to cancel the current stat points allocation.
signal cancel_stats_points()

# ─── Item & Loot Signals ─────────────────────────────────────────────────────
## Emitted when a lootable item comes into range and is added to the available list.
signal lootable_item_added(item: Item)
## Emitted when a lootable item goes out of range and is removed from the available list.
signal lootable_item_removed(item: Item)
## Emitted to display hover info for a specific lootable item.
signal display_lootable_item_hover_info(item: Item)
## Emitted to hide hover info for a specific lootable item.
signal hide_lootable_item_hover_info(item: Item)
## Emitted when selected lootable items are actually picked up into the inventory.
signal selected_lootable_items_picked_up(slots: Array[Item])

# ─── Inventory Signals ───────────────────────────────────────────────────────
## Emitted when an item is added to the inventory.
signal items_added_to_inventory(slots: Array[Item])

## Emitted when an item is removed from the inventory.
signal items_removed_from_inventory(slots: Array[Item])

## Emitted when an item is dropped from an inventory slot.
signal item_dropped_from_inventory(slot: Item)