## EventBus
## Manages global signals and events for the game, acting as a central hub
## for communication between disparate systems.
extends Node
# ─── UI & HUD Signals ────────────────────────────────────────────────────────
@warning_ignore("UNUSED_SIGNAL")
## Emitted to initialize the hero stats UI.
signal initialize_hero_stats_ui(cls: CharacterClass)
@warning_ignore("UNUSED_SIGNAL")
## Emitted to update the hero stats UI.
signal update_hero_stats_ui(stats: CharacterStats)
@warning_ignore("UNUSED_SIGNAL")
## Emitted when the hero's avatar texture is updated.
signal update_hero_avatar_texture(texture: Texture2D)
## Emitted to update the HP bar UI value.
@warning_ignore("UNUSED_SIGNAL")
signal update_hp_bar_value(value: float)
## Emitted to update the Mana bar UI value.
@warning_ignore("UNUSED_SIGNAL")
signal update_mana_bar_value(value: float)

# ─── Game & Combat Signals ───────────────────────────────────────────────────
## Emitted when an enemy dies.
@warning_ignore("UNUSED_SIGNAL")
signal enemy_died(enemy: Enemy)
## Emitted when an enemy spawns at a specific position.
@warning_ignore("UNUSED_SIGNAL")
signal enemy_spawned(enemy: Enemy, spawn_position: Vector2)
## Emitted when the player's experience points change.
@warning_ignore("UNUSED_SIGNAL")
signal xp_changed(current: int)
## Emitted when the player levels up.
@warning_ignore("UNUSED_SIGNAL")
signal level_up(new_level: int)

# ─── Stats and Stats Allocation Signals ────────────────────────────────────────────────
## Emitted when a stat point is allocated.
@warning_ignore("UNUSED_SIGNAL")
signal stat_allocated(stat_name: String)
## Emitted when a stat point is deallocated.
@warning_ignore("UNUSED_SIGNAL")
signal stat_deallocated(stat_name: String)
## Emitted when stats are updated in the UI.
@warning_ignore("UNUSED_SIGNAL")
signal stats_updated()
## Emitted when update stats
@warning_ignore("UNUSED_SIGNAL")
signal update_stats(stats: CharacterStats)
## Emitted to save the current stat points allocation.
@warning_ignore("UNUSED_SIGNAL")
signal save_stats_points()
## Emitted to cancel the current stat points allocation.
@warning_ignore("UNUSED_SIGNAL")
signal cancel_stats_points()

# ─── Item & Loot Signals ─────────────────────────────────────────────────────
## Emitted when a lootable item comes into range and is added to the available list.
@warning_ignore("UNUSED_SIGNAL")
signal lootable_item_added(item: Item)
## Emitted when a lootable item goes out of range and is removed from the available list.
@warning_ignore("UNUSED_SIGNAL")
signal lootable_item_removed(item: Item)
## Emitted to display hover info for a specific lootable item.
@warning_ignore("UNUSED_SIGNAL")
signal display_lootable_item_hover_info(item: Item)
## Emitted to hide hover info for a specific lootable item.
@warning_ignore("UNUSED_SIGNAL")
signal hide_lootable_item_hover_info(item: Item)
## Emitted when selected lootable items are actually picked up into the inventory.
@warning_ignore("UNUSED_SIGNAL")
signal selected_lootable_items_picked_up(slots: Array[Item])

# ─── Inventory Signals ───────────────────────────────────────────────────────
## Emitted when an item is added to the inventory.
@warning_ignore("UNUSED_SIGNAL")
signal items_added_to_inventory(slots: Array[Item])

## Emitted when an item is removed from the inventory.
@warning_ignore("UNUSED_SIGNAL")
signal items_removed_from_inventory(slots: Array[Item])

## Emitted when an item is dropped from an inventory slot.
@warning_ignore("UNUSED_SIGNAL")
signal item_dropped_from_inventory(slot: Item)

## Emitted when try to show item table details.
@warning_ignore("UNUSED_SIGNAL")
signal show_item_table_details(item: Item)

## Emitted when try to hide item table details.
@warning_ignore("UNUSED_SIGNAL")
signal hide_item_table_details()

# ─── Equipement Signals ──────────────────────────────────────────────────────
## Emitted when try to equip an item.
@warning_ignore("UNUSED_SIGNAL")
signal equip_item(inventory_slot: InventorySlot)

## Emitted when an item is equipped.
@warning_ignore("UNUSED_SIGNAL")
signal item_equipped(inventory_slot: InventorySlot)

## Emitted when an item is unequipped.
@warning_ignore("UNUSED_SIGNAL")
signal item_unequipped(item: Equipable)

## Emitted when try to switch equipements.
@warning_ignore("UNUSED_SIGNAL")
signal switch_equipements()
