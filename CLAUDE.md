# CLAUDE.md — 2D Action RPG (Godot 4)

## Project Overview
A 2D Action RPG with a dark fantasy, Moroccan, and Arabic folklore theme. Medium scope (~3-4 hours gameplay) built natively in **Godot 4.x** using **GDScript**. The codebase consists of 57 modular GDScript files implementing state machines, dynamic equipment/gems/potion systems, inventory, stat allocations, pathfinding AI, and custom UI components.

- **Viewport:** 1280×720, `canvas_items` stretch mode
- **Rendering:** Mobile renderer, DirectX 12 (Windows), pixel art (nearest-filter textures)

---

## Tech Stack & Commands
*   **Engine:** Godot 4.6 (GDScript)
*   **Rendering:** 2D pixel art (`textures/canvas_textures/default_texture_filter=0`)
*   **Physics:** `CharacterBody2D` for entities, `Area2D` for hitboxes/hurtboxes/projectiles/drops
*   **Pathfinding:** `NavigationAgent2D` for intelligent enemy pathfinding and obstacle avoidance
*   **Running the Project:** Execute `godot --path .` from the command line, or open the project folder directly in the Godot 4 Editor.

---

## Input Actions

| Action | Key / Button |
| :--- | :--- |
| `move_left` | A |
| `move_right` | D |
| `move_up` | W |
| `move_down` | S |
| `attack` | Left Mouse Button |
| `interact` | E or F |
| `pause` | Escape |
| `open_inventory` | I or Tab |

---

## Architecture & Class Hierarchy

### Scene Hierarchy
```
Character.tscn              → Base CollisionShape2D + Label (debug) + StateMachine
  ├── Player.tscn           → Adds Camera2D, ComboAttackCD, Hurtbox, StateMachine, PickableDetection
  │     ├── Warrior.tscn    → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox (melee)
  │     ├── Archer.tscn     → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, SpawningPositions, Container (ranged)
  │     └── Mage.tscn       → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, SpawningPositions, Container, DetectionZone (spell)
  └── Enemy.tscn            → Adds NavigationAgent2D, DetectionZone, Hurtbox, StateMachine, WanderCD, EnemyStats UI
        └── Goblin.tscn     → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox (melee enemy)
```

### Script Hierarchy
```
Character.gd (CharacterBody2D)  → Base world entity: entity_name, speed, movement, state machine, label debug
  ├── NPC.gd (NPC)             → Non-combat entity: interaction_area, npc_name, dialogue_text, _interact()
  └── Combatant.gd (Combatant) → Base combat entity: animation_BA_playback, take_damage (defense reduction), hit flashing, combat virtual hooks
        ├── Player.gd (Player) → Input, combo management, movement, PickableDetection callbacks
        │     ├── Warrior.gd   → Melee: loads warrior.tres in _ready(), handles Hitbox area_entered → take_damage
        │     ├── Archer.gd    → Ranged: loads archer.tres in _ready(), targets enemies, spawns Arrow projectiles
        │     └── Mage.gd      → Ranged: loads mage.tres in _ready(), targets enemies, spawns WaterBullet projectiles
        └── Enemy.gd (Enemy)   → Base AI: NavigationAgent2D pathfinding, wander/chase movement, item dropping, HP bar UI
              └── Goblin.gd    → Melee enemy: animation blending, Hitbox area_entered → take_damage
```

> **Class loading pattern:** Each concrete player class (`Warrior`, `Archer`, `Mage`) loads its own `.tres` resource with `load("res://resources/classes/<class>.tres")` inside its `_ready()` and calls `_load_classe(cls)`, which sets `max_health`, `max_mana`, `speed`, `combo_chain`, and registers with `GameManager`.

---

## Node-Based State Machine

The state machine separates entity states into decoupled, modular nodes under a parent `StateMachine`.

*   **StateMachine (`state_machine.gd`):**
    *   `await owner.ready` before registering — ensures the owner (Character) is fully initialized.
    *   Registers all direct child nodes that inherit `State` into `states` dict (keys are `node.name.to_lower()`).
    *   `transition_to(state_name: String)` is the public API — calls `_on_state_transitioned()` internally.
    *   Delegates `_process`, `_physics_process`, and `_unhandled_input` to the `current_state`.
    *   Prints an error (does NOT crash) if a requested state name is not found.
*   **State (`state.gd`):** Abstract base class with lifecycle hooks `enter()`, `exit()`, `handle_input()`, `update()`, `physics_update()`. References `actor: Character` (`owner as Character`) and `state_machine: StateMachine` (`get_parent() as StateMachine`) via `@onready`.
    *   Emits `transitioned(state_name: String)` signal to request state changes.

### Player States (`states/player/`)
| Class Name | Lowercase Key | Description |
| :--- | :--- | :--- |
| `PlayerIdleState` | `playeridlestate` | Calls `actor._idle()`, transitions to `playerrunstate` on movement input. |
| `PlayerRunState` | `playerrunstate` | Calls `actor._move()`, transitions to `playeridlestate` when no movement. |
| `PlayerAttackState` | `playerattackstate` | Stops movement, calls `actor._on_attack_pressed()`. Listens to `attack_ended` signal before returning to `playeridlestate`. |
| `PlayerDeadState` | `playerdeadstate` | Stops movement, triggers `actor._die()`. |

### Enemy States (`states/enemy/`)
| Class Name | Lowercase Key | Description |
| :--- | :--- | :--- |
| `EnemySpawnedState` | `enemyspawnedstate` | Loads `EnemyParams`, records spawn coordinates, connects to spawner cleanup signals, transitions to idle. |
| `EnemyIdleState` | `enemyidlestate` | Stops movement, travels to idle animation, starts wander cooldown. Transitions to chase or attack reactively. |
| `EnemyWanderState` | `enemywanderstate` | Picks a random cardinal direction (LEFT, RIGHT, UP, DOWN) and navigates to that wander position. Returns to idle on arrival. |
| `EnemyPatrolState` | `enemypatrolstate` | Navigates enemy back to its `spawn_position` if it wandered too far or lost aggro. |
| `EnemyRunState` | `enemyrunstate` | Basic running state delegating to `actor._move()`. |
| `EnemyChaseState` | `enemychasestate` | Updates `NavigationAgent2D` to track player. Leashes to `MAX_DISTANCE_TO_SPAWN_LOCATION` (700 px). Transitions to attack when in range. |
| `EnemyAttackState` | `enemyattackstate` | Disables velocity, triggers cooldowned attack animation. Re-evaluates target position after each attack. |
| `EnemyDeadState` | `enemydeadstate` | Disables movement, triggers death animation, alerts spawning system to queue respawn via `EventBus.enemy_died`. |

---

## Dynamic Gameplay Systems

### Lootable Items (Loot & Pickup)
*   **Naming Convention:** All dropped and picked items follow the `Lootable Item` convention in UI and logic.
*   **`DropItem` (`drop.gd`, `Area2D`):** Physical world representation of a dropped item. Fields: `item: DataItem`, `despawn_time: float = 30.0`. Retrieves icon texture via `item.get_item_texture()`. Starts a `DropCD` timer on `_ready()` and `queue_free()`s on timeout. Belongs to the `pickable` group.
*   **Player Detection:** Player's `PickableDetection` (Area2D) detects overlapping `DropItem` nodes. On enter: `EventBus.lootable_item_added.emit(item)`. On exit: `EventBus.lootable_item_removed.emit(item)`.
*   **UI Integration:** `InGameUI` catches signals, populates `LootableItemSlot` panels in a `GridContainer` (up to 20 slots). Players can multi-select slots to pick up, triggering `EventBus.selected_lootable_items_picked_up`.
*   **`LootableItemSlot` state:** Displays texture via `item.get_item_texture()`. Has three visual states (`normal`, `hover`, `pressed`) implemented via `StyleBoxFlat` border-color overrides.

### Inventory System (`inventory_slot.gd`, `in_game_ui.gd`)
Full 56-slot grid-based inventory in the **Inventory Tab** of the HUD panel.
*   **`InventorySlot` (Panel):** Holds one `DataItem`. Displays texture via `item.get_item_texture()`. Right-click opens `PopupMenu` with:
    *   **Equip** — enabled if item is `EquipableItem` or `ConsumableItem`. Emits `EventBus.equip_item(inventory_slot)`.
    *   **Use** — stub (prints "use item").
    *   **Drop** — emits `EventBus.item_dropped_from_inventory(item)`, clears slot.
*   **Hover tooltip:** `mouse_entered` emits `EventBus.show_item_table_details(item)`. `mouse_exited` emits `EventBus.hide_item_table_details()`.
*   **Item Drop-back Flow:** `GameManager._on_item_dropped_from_inventory()` → `drop_item(item)` → gets first `enemies_spawner` group node's drop zone → places `drop.tscn` at randomized offset (`drop_range = 50.0`) near player.

### Potions & Consumables System (`consumable_item.gd`, `potion_slot.gd`, `player_data.gd`)
*   **Item Hierarchy:** `DataItem` → `ConsumableItem` (Legacy `Item` → `Consumable` → `Potion` deprecated).
*   **Types & Enums:** `ConsumableItem.ConsumableType` (`POTION`, `POISON`) and `PotionSlot.PotionSlotType` (`HEALTH_POTION`, `MANA_POTION`).
*   **Equip / Routing:** Right-clicking a consumable in the inventory and selecting "Equip" triggers `GameManager._on_equip_item()`, which routes it to `PlayerData.add_potion(potion)` and emits `EventBus.potions_added_to_list.emit(potion)`.
*   **HUD Slot (`PotionSlot`):** Displays current potion texture (`item.get_item_texture()`) and count (`potions: Array[ConsumableItem]`). Right-click opens `PopupMenu` with:
    *   **Unequip** — emits `EventBus.potions_unequipped(potion)` → returns item to inventory.
    *   **Consume** — emits `EventBus.potions_consumed(potion)` → triggers potion effect via `GameManager._on_potion_consumed()` (heals HP/MP by `heal_amount` according to `potion_type`), then emits `EventBus.stats_updated`.

### Equipment System (`equipement_slot.gd`, `in_game_ui.gd`, `player_data.gd`)
Full 10-slot equipment panel in the **Equipements Tab** of the HUD. Each slot is an `EquipementSlot` (Panel) with a `placeholder_image`, an item `TextureRect` (using `EquipableItem.get_item_texture()`), and a right-click **Unequip** context menu.

**Equipment Slots (keyed by `slot_key` string and `PlayerData.__equipable_items` dictionary key):**
| Slot Key | Type | UI Node (in `InGameUI`) |
| :--- | :--- | :--- |
| `HELMET` | `EquipableItem.ArmorType.HEAD` / `HELMET` | `helmet_slot` |
| `CHEST` | `EquipableItem.ArmorType.CHEST` / `ARMOR` | `chest_slot` |
| `BOOTS` | `EquipableItem.ArmorType.FEET` / `BOOTS` | `boots_s_lot` *(note: typo in node name)* |
| `SHIELD` | `EquipableItem.ArmorType.SHIELD` | `shield_slot` |
| `RING` | `EquipableItem.ArmorType.RING` | `ring_slot` |
| `AMULET` | `EquipableItem.ArmorType.NECKLACE` / `AMULET` | `amulet_slot` |
| `CLOAK` | `EquipableItem.ArmorType.CLOAK` | `cloak_slot` |
| `WEAPON` | `EquipableItem.WeaponType` (SWORD, AXE, DAGGER, etc.) | `weapon_slot` |
| `GLOVES` | *(reserved — no UI slot wired)* | — |
| `PET` | *(reserved)* | `pet_slot` |

**Equip Flow:**
1. Right-click `InventorySlot` → select "Equip" → `EventBus.equip_item(inventory_slot)`.
2. `GameManager._on_equip_item()`: validates level requirement (`required_level`) and `player_class` ("ALL" or matching player class).
3. Determines equipment category key: `equipment_type.to_upper()`.
4. If slot empty: `PlayerData.add_equipable_item(item)` → `stats_manager.calculate_equipment_bonus(item)` → `EventBus.item_equipped.emit(inventory_slot)`.
5. If slot occupied (swap): removes old item bonus, adds new item, puts old item back into inventory slot.
6. After any equip/unequip: `player_ref.character_class.set_class_stats(StatsData.get_stats())` and `EventBus.stats_updated.emit(StatsData)`.
7. `InGameUI._on_item_equipped()` routes to the correct `EquipementSlot.set_item()` and clears the `InventorySlot`.

**Stat Effect & Gem Bonuses:**
`StatsManager.calculate_equipment_bonus(equipement, operation)` evaluates `equipement.base_damage` for weapon power bonus and `equipement.base_defense` for armor defense bonus in `StatsData.get_stats()`. Socketed gems and stat bonuses are managed via `EquipableItem` methods.

### Gem System (`gem.gd`, `gem_panel.gd`, `equipable_item.gd`)
*   **Gems Socketing:** `EquipableItem` supports up to `gems_slots_count` socketed gems (`gems: Array[Gem]`).
*   **Gem Types & Stat Mappings:**
    *   `RUBY` → `DEX`
    *   `SAPPHIRE` → `STR`
    *   `EMERALD` → `LUC`
    *   `TOPAZ` → `INT`
    *   `AMETHYST` → `WIS`
    *   `DIAMOND` → `REC`
*   **Gem Levels:** Levels 1 to 3. Stat bonus array indexed by `gem_level - 1`.

### Item Tooltip / Table Details (`equipable_table_details.gd`, `armor_table_details.gd`, `weapon_table_details.gd`, `item_stats_row.gd`)
Hovering an `InventorySlot` shows a floating popup with full item details:
*   `EventBus.show_item_table_details(item)` → `InGameUI._on_show_item_table_details()`:
    *   Instantiates `armor_table_details_scene` (if `item.is_armor()`) or `weapon_table_details_scene`.
    *   Adds to `$Popups` node. Calls `set_equipable_item(item as EquipableItem)`. Positions near mouse, with viewport-edge clamping.
*   `EventBus.hide_item_table_details()` → frees the instance.
*   **`EquipableTableDetails` (base):** Shows name, class restriction, level (`required_level`), texture (`get_item_texture()`), category (`equipment_type`), price, and details.
*   **`WeaponTableDetails`:** Extends base; displays base attack power label (`base_damage`).
*   **`ArmorTableDetails`:** Extends base; displays base defense label (`base_defense`).

### Projectiles (`arrow.gd`, `water_bullet.gd`)
*   Both extend `Area2D`. Fields: `speed = 1000.0`, `max_distance = 600.0`, `direction`, `velocity`, `distance_traveled`.
*   `Arrow` emits `arrow_hit(area)`. `WaterBullet` emits `bullet_hit(area)`.
*   **Lifecycle:** Instantiated as top-level (`set_as_top_level(true)`), added to `arrows_container` / `bullets_container`. Auto `queue_free()` when `distance_traveled >= max_distance` or on obstacle hit.
*   **Spawning position:** Both `Archer` and `Mage` use a scene-internal `%ArrowSpawningPosition` / `%BulletSpawningPosition` Marker2D. Position offset (`Vector2(26.0, -51.0)`) is mirrored by `last_facing_dir`.
*   **Targeting:** The projectile always fires toward the `target`'s `Hurtbox` node global position (if it exists), else the target body's position. Falls back to `last_facing_dir` if no target.
*   **Trigger:** AnimationPlayer calls a method in the script (e.g., `_on_animation_editor_arrow_attack()`), which emits a private signal (`_animation_editor_arrow_attack`), which is connected to the actual spawning handler. This double-indirection lets the animator trigger projectiles at an exact frame.
*   **Range:** `attack_range = 300.0` for Archer, `attack_range = 500.0` for Mage. Projectile `max_distance` is computed as `attack_range - POSITION_OFFSET.x - SPRITE_WIDTH/2`.

### Enemies Spawner (`enemies_spawner.gd`)
*   **Type:** `Node2D`, belongs to the `enemies_spawner` group.
*   **Exports:** `spawn_point: Marker2D`, `enemies: Array[PackedScene]`, `spawn_circle_radius: float = 100.0`, `respawn_cd: float = 60.0`, `wander_cd_time: float = 20.0`.
*   **`%DropZone` (Node2D):** Child node used as parent for all `DropItem` instances spawned by enemies under this spawner.
*   **Spawning:** On `_ready()`, spawns one enemy instance per entry in `enemies` array. `_spawn_enemy()` picks a random enemy scene, instantiates it, adds as child, and emits `EventBus.enemy_spawned`.
*   **Respawn:** `remove_enemy(enemy)` starts a `respawn_cd` timer then calls `_spawn_enemy()`.
*   **Drop Cleanup:** Connects to `EventBus.selected_lootable_items_picked_up` → `remove_selected_drops(items: Array[DataItem])` queue-frees matching `DropItem` children from `DropZone`.
*   **`get_drop_zone()` → Node:** Used by `GameManager.spawn_enemy_items()` and `drop_item()` to locate the correct parent for new drops.

### Stat Allocation System
The stat system is split across three layers — data (`StatsData`), logic (`StatsManager`), and presentation (`StatsUI`):

*   **5 points per level-up** (`POINTS_PER_LEVEL = 5` in `StatsManager`, `POINTS_STATS_PER_LEVEL = 5` in `StatsData`).
*   **Stat Lists:** `STAT_NAMES = ["HP", "MP", "STR", "REC", "INT", "WIS", "DEX", "LUC"]`, `STAT_NAMES_NO_FLT = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]`.
*   **Signal flow:** UI buttons → `EventBus.stat_allocated/stat_deallocated` → `GameManager` (connected in `_ready()`) → `StatsManager.add_stat_point/sub_stat_point` → `StatsData` mutation → `EventBus.stats_updated(StatsData)` + `EventBus.stat_points_available_changed(points)` → `StatsUI` update.
*   **Working copy (`__allocated_stats`):** Dict seeded from class base stats via `get_allocated_stats()` on init. Updated by `StatsData.add_stat_point()` / `sub_stat_point()`.
*   **Backup copy (`__temp_allocated_stats`):** Stores the last committed state. Cannot go below temp values.
*   **`save_stats()`:** Copies working → backup. Sets `__allocate_point_saved = true` if `__stat_points_available <= 0`.
*   **`cancel_stats()`:** Reverts working from backup. Sets `__allocate_point_saved = false`.
*   **XP:** Starts at 0, target is `75` XP for level 2. Each level-up scales target by `level_scaler = 1.2`.

---

## Global Autoloads (Singletons)

Autoload order in `project.godot`: `EventBus` → `GameManager` → `SaveManager` → `PlayerData` → `StatsData`.

> **Note:** `StatsManager` is **NOT** an autoload. It is instantiated as `StatsManager.new()` inside `GameManager` and stored at `GameManager.stats_manager`.

### `EventBus` (`event_bus.gd`)
Centralized signal broker. All signals carry `@warning_ignore("UNUSED_SIGNAL")`.

| Group | Signal | Payload |
| :--- | :--- | :--- |
| **UI/HUD Init** | `initialize_hero_stats_ui` | *(none)* |
| | `update_hero_avatar_texture` | `texture: Texture2D` |
| **Combat/Progression** | `enemy_died` | `enemy: Enemy` |
| | `enemy_spawned` | `enemy: Enemy, spawn_position: Vector2` |
| | `level_up` | `new_level: int` *(emitted without arg from GameManager)* |
| **Stats Bars** | `hero_hp_changed` | `current_hp: float, max_hp: float` |
| | `hero_mp_changed` | `current_mp: float, max_mp: float` |
| | `hero_xp_changed` | `current_xp: int, total_xp: int` |
| **Stats Allocation** | `stat_allocated` | `stat_name: String` |
| | `stat_deallocated` | `stat_name: String` |
| | `stats_updated` | `stats_data: StatsData` |
| | `stat_points_available_changed` | `points: int` |
| | `save_stats_points` | *(none)* |
| | `cancel_stats_points` | *(none)* |
| **Loot** | `lootable_item_added` | `item: DataItem` |
| | `lootable_item_removed` | `item: DataItem` |
| | `display_lootable_item_hover_info` | `item: DataItem` |
| | `hide_lootable_item_hover_info` | `item: DataItem` |
| | `selected_lootable_items_picked_up` | `slots: Array[DataItem]` |
| **Inventory** | `items_added_to_inventory` | `slots: Array[DataItem]` |
| | `items_removed_from_inventory` | `slots: Array[DataItem]` |
| | `item_dropped_from_inventory` | `slot: DataItem` |
| **Item Details** | `show_item_table_details` | `item: DataItem` |
| | `hide_item_table_details` | *(none)* |
| **Equipment** | `equip_item` | `inventory_slot: InventorySlot` |
| | `item_equipped` | `inventory_slot: InventorySlot` |
| | `item_unequipped` | `item: EquipableItem` |
| | `switch_equipements` | *(none — reserved)* |
| **Potions** | `potions_added_to_list` | `potion: ConsumableItem` |
| | `potions_unequipped` | `potion: ConsumableItem` |
| | `potions_consumed` | `potion: ConsumableItem` |
| **Merchant** | `buy_item` | `value: float, data_item: DataItem` |

### `StatsData` (`stats_data.gd`)
**Pure data layer autoload.** Owns the live `CharacterStats` resource and all stat allocation state. No signal emissions — called by `StatsManager`.

*   **`initialize_from_character_stats(cs: CharacterStats)`:** Duplicates the `CharacterStats` resource, seeds `__allocated_stats` and `__temp_allocated_stats`, copies bonus stats, and calls `__stats.update_current_health_and_mana()`.
*   **`get_stats() → CharacterStats`:** Returns the live stats resource.
*   **State tracking:** `__stat_points_available`, `__temp_stat_points_available`, `__allocate_point_saved`, `__allocated_stats`, `__temp_allocated_stats`.
*   **`add_stat_point(stat_name)` / `sub_stat_point(stat_name)` → bool:** Mutate `__allocated_stats`, call `sync_allocated_to_base()`, update available points.
*   **`save_stats()` / `cancel_stats()`:** Commit or revert allocation state.
*   **`sync_allocated_to_base()`:** Calls `__stats.from_dict_to_base_stats(__allocated_stats)` to push allocations into the live `CharacterStats`.
*   **Accessors:** `get_total(key)`, `get_allocated_stat(key)`, `get_temp_allocated_stat(key)`, `get_stat_points_available()`, `get_base_weapon_power()`, `get_base_armor_defense()`, `get_base_armor_resist()`, and their setters.
*   **Constants:** `STAT_NAMES`, `STAT_NAMES_NO_FLT`, `POINTS_STATS_PER_LEVEL`.

### `PlayerData` (`player_data.gd`)
Central store for player **progress and inventory**. Stat allocation has been moved to `StatsData`/`StatsManager`.

*   **Level & XP:** `get/set_player_level()`, `get/set_current_xp()` (emits `hero_xp_changed`), `get/set_total_xp_to_next_level()` (emits `hero_xp_changed`). Starts at level 1, 0 XP, 75 XP target.
*   **Inventory:** `add/remove_lootable_item(item: DataItem)`, `add/remove_inventory_item(item: DataItem)`.
*   **Equipment:** `get_equipements() → Dictionary`, `add/remove_equipable_item(item: EquipableItem)`. Keyed by uppercase equipment category string (`WEAPON`, `HELMET`, `CHEST`, `BOOTS`, `SHIELD`, `RING`, `AMULET`, `CLOAK`, etc.).
*   **Potions:** `add_potion(potion: ConsumableItem)`, `remove_potion_from_list(potion: ConsumableItem)`. Internally stores `__potions = {"HEALTH": [], "MANA": []}`.
*   **Constants** (kept for backward compat): `STAT_NAMES`, `STAT_NAMES_NO_FLT`, `POINTS_STATS_PER_LEVEL`.

### `GameManager` (`game_manager.gd`)
Orchestrates top-level game flow. Key public variables: `player_ref: Character`, `level_scaler: float = 1.2`, `drop_range: float = 50.0`, `stats_manager: StatsManager`.

*   **`register_player(player)`:** Sets `player_ref`, calls `stats_manager.initialize(player.character_class.get_class_stats())`, emits `EventBus.initialize_hero_stats_ui`.
*   **`add_xp(amount)`:** Increments XP via `PlayerData.set_current_xp()` (which emits `hero_xp_changed`), calls `level_up()` if threshold met.
*   **`level_up()`:** Increments `player_level`, calls `stats_manager.update_available_points_on_level_up()`, `scaling_level_up()`, `StatsData.get_stats().update_current_health_and_mana()`, emits `EventBus.level_up`.
*   **`spawn_enemy_items(enemy)`:** Gets drop zone from `enemy.get_parent().get_drop_zone()`, calls `enemy._drop_item()`, adds drops at randomized positions.
*   **`drop_item(item: DataItem)`:** Loads `drop.tscn`, gets the first `enemies_spawner` group node's drop zone, places item near `player_ref.global_position` ± `drop_range`.
*   **`_ready()` signal connections:** `enemy_died`, `stat_allocated`→`stats_manager.add_stat_point`, `stat_deallocated`→`stats_manager.sub_stat_point`, `save_stats_points`→`stats_manager.save_stats`, `cancel_stats_points`→`stats_manager.cancel_stats`, `buy_item`→`_on_buy_item`, plus all loot/inventory/equipment/potion signals.

### `StatsManager` (`stats_manager.gd`)
**Business logic layer.** Instantiated inside `GameManager` (`var stats_manager: StatsManager = StatsManager.new()`). Wraps `StatsData` mutations and emits the appropriate `EventBus` signals after each change.

*   **`initialize(character_stats)`:** Delegates to `StatsData.initialize_from_character_stats()`, then emits `stats_updated` and `stat_points_available_changed`.
*   **`add_stat_point(stat_name)` / `sub_stat_point(stat_name)`:** Delegates to `StatsData`, emits signals on success.
*   **`save_stats()` / `cancel_stats()`:** Delegates to `StatsData`, always emits signals.
*   **`update_available_points_on_level_up()`:** Adds `POINTS_PER_LEVEL` to available points, resets temp points and `allocate_point_saved`, emits signals.
*   **`calculate_equipment_bonus(equipement: EquipableItem, operation = "equip")`:** Evaluates `equipement.base_damage` for weapon power and `equipement.base_defense` for armor defense in `StatsData.get_stats().add_stat_bonus()` / `remove_stat_bonus()`.
*   **`get_total(stat_name)` / `get_allocated_stat(stat_name)` / `get_temp_allocated_stat(stat_name)`:** Thin delegation wrappers to `StatsData`.


### `SaveManager` (`save_manager.gd`)
Stub node. Reserved for save/load persistence logic. No active implementation.

---

## Project Folder Structure

```
res://
├── assets/                     → Audio, sprite sheets, tilesets, UI themes
│   ├── sprites/player/         → Class assets (warrior, archer, mage)
│   ├── sprites/enemies/        → Monster assets (goblin, etc.)
│   ├── tilesets/
│   ├── ui/
│   └── audio/{sfx,music}/
├── data/
│   └── items_data.json         → Master item reference database (reference only, not runtime)
├── scenes/
│   ├── world/
│   │   ├── world.tscn          → Main game world scene
│   │   └── zones/
│   ├── entities/
│   │   ├── player/             → character.tscn, player.tscn, warrior.tscn, archer.tscn, mage.tscn
│   │   │                         arrow.tscn, water_bullet.tscn
│   │   ├── enemies/            → enemy.tscn, goblin.tscn, enemies_spawner.tscn
│   │   ├── items/              → drop.tscn
│   │   └── npcs/               → (reserved)
│   ├── ui/
│   │   ├── in_game_ui.tscn
│   │   ├── lootable_item_slot.tscn
│   │   ├── stat_container.tscn
│   │   ├── inventory_slot.tscn
│   │   ├── equipement_slot.tscn
│   │   ├── potion_slot.tscn
│   │   └── item/               → armor_table_details.tscn, weapon_table_details.tscn,
│   │                              item_stats_row.tscn, gem_panel.tscn
│   └── components/             → (reserved)
├── scripts/
│   ├── autoloads/              → event_bus.gd, game_manager.gd, player_data.gd, save_manager.gd,
│   │                             stats_data.gd, stats_manager.gd
│   ├── entities/               → character.gd, combatant.gd, npc.gd, player.gd, enemy.gd, warrior.gd, archer.gd, mage.gd,
│   │   │                         goblin.gd, arrow.gd, water_bullet.gd, enemies_spawner.gd,
│   │   │                         in_game_ui.gd, lootable_item_slot.gd, inventory_slot.gd,
│   │   │                         equipement_slot.gd, potion_slot.gd, stat_container.gd,
│   │   │                         stats_ui.gd, equipable_table_details.gd, armor_table_details.gd,
│   │   │                         weapon_table_details.gd, gem_panel.gd, item_stats_row.gd,
│   │   │                         item_stats_upgrade_label.gd
│   │   └── state_machine/      → state.gd, state_machine.gd
│   │       └── states/
│   │           ├── player/     → player_idle_state.gd, player_run_state.gd,
│   │           │                 player_attack_state.gd, player_dead_state.gd
│   │           └── enemy/      → enemy_spawned_state.gd, enemy_idle_state.gd, enemy_wander_state.gd,
│   │                             enemy_patrol_state.gd, enemy_run_state.gd, enemy_chase_state.gd,
│   │                             enemy_attack_state.gd, enemy_dead_state.gd
│   ├── resources/              → attack_data.gd, drop.gd
│   └── utils/
└── resources/
    ├── classes/                → warrior.tres, archer.tres, mage.tres, priest.tres + character_classes.gd
    ├── stats/                  → warrior_stats.tres, archer_stats.tres, mage_stats.tres, priest.tres + character_stats.gd
    ├── attacks/                → combo attack configurations (.tres)
    ├── enemies/                → enemy_params.gd + goblin.tres
    └── items/                  → item.gd, equipable.gd, weapon.gd, armor.gd, gem.gd, consumable.gd, potion.gd
        ├── gems/               → amethyst.tres, diamond.tres, emerald.tres, ruby.tres, sapphire.tres, topaz.tres
        ├── warrior/
        │   ├── weapons/        → hand_axe.tres, iron_dagger.tres
        │   └── armors/         → copper_breastplate.tres, iron_greaves.tres, iron_soldier_helm.tres, round_wooden_shield.tres
        └── mage/
            ├── weapons/        → (reserved)
            └── armors/         → (reserved)
```

---

## Data Files

### `data/items_data.json` — Master Item Reference Database
A flat JSON reference database documenting all game items by tier and category. **Reference data only — NOT loaded at runtime.** Documents sprite sheet grid coordinates (`column_x`, `row_y`), IDs, level requirements, and base stats.

---

## Physics Layers & Collision Settings

| Layer | Name | Purpose |
| :--- | :--- | :--- |
| **1** | `world` | Solid walls, terrain, tilemaps |
| **2** | `player` | Player physical boundaries |
| **3** | `enemy` | Enemy physical boundaries |
| **4** | `player_hitbox` | Player's damage-dealing areas |
| **5** | `enemy_hitbox` | Enemy's damage-dealing areas |
| **6** | `player_hurtbox` | Area where player accepts damage |
| **7** | `enemy_hurtbox` | Area where enemy accepts damage |
| **8** | `items` | Dropped item `DropItem` Area2D nodes |

### Hitbox / Hurtbox Settings

| Node | Layer | Mask | Monitoring | Monitorable |
| :--- | :--- | :--- | :--- | :--- |
| **Player Body CollisionShape** | 2 | 1 | — | — |
| **Enemy Body CollisionShape** | 3 | 1 | — | — |
| **Player Hurtbox** | 6 | none | OFF | ON |
| **Enemy Hurtbox** | 7 | none | OFF | ON |
| **Warrior Hitbox (Melee)** | 4 | 7 | ON | OFF |
| **Enemy Hitbox (Melee)** | 5 | 6 | ON | OFF |

---

## Node Groups

Registered in `project.godot` under `[global_group]`:

| Group | Used By |
| :--- | :--- |
| `character` | Base character nodes |
| `player` | Player body (used by enemy detection zone to acquire target) |
| `enemy` | Enemy bodies (used by projectile/hitbox hit detection) |
| `warrior` | Warrior-specific nodes |
| `archer` | Archer-specific nodes |
| `goblin` | Goblin-specific nodes |
| `enemies_spawner` | `EnemiesSpawner` nodes (used by `GameManager.drop_item()`) |
| `pickable` | `DropItem` Area2D nodes (used by player's `PickableDetection`) |

---

## Resource Schemas

### `CharacterClass` (`character_classes.gd`)
```gdscript
class_name CharacterClass
extends Resource

enum PlayerType { WARRIOR, ARCHER, MAGE, PRIEST, ALL }

@export var player_type: PlayerType = PlayerType.WARRIOR
@export var avatar_texture: Texture2D
@export var speed: float = 300.0
@export var combo_chain: Array[AttackData] = []
@export var base_stats: CharacterStats

func set_class_stats(stats: CharacterStats) -> void
func get_class_stats() -> CharacterStats
func get_class_stats_instance() -> CharacterStats
```

### `CharacterStats` (`character_stats.gd`)
```gdscript
class_name CharacterStats
extends Resource

# Base stats (allocated points are written back here by StatsData.sync_allocated_to_base)
@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var DEX: int = 0
@export var WIS: int = 0
@export var LUC: int = 0
@export var CURRENT_HEALTH: float = 0.0   # ← NEW: tracks live HP
@export var CURRENT_MANA: float = 0.0     # ← NEW: tracks live MP

@export var __bonus_stats: Dictionary  # max_health, max_mana, STR, REC, INT, WIS, DEX, LUC, weapon_power, armor_defense, armor_resist

# Core lifecycle
func get_instance() -> CharacterStats                  # duplicate()
func update_current_health_and_mana() -> void          # resets CURRENT_HEALTH/MANA to max

# Stat formulas (all computed on the resource itself)
func get_max_hp() -> float      # 100 + (REC + bonus_REC) * 5 + bonus_max_health
func get_max_mp() -> float      # 50 + (WIS * 5) + bonus_max_mana
func get_current_hp() -> float
func get_current_mp() -> float
func set_current_hp(value: float) -> void   # clamped 0..get_max_hp()
func set_current_mp(value: float) -> void   # clamped 0..get_max_mp()
func get_def() -> float         # REC + bonus_armor_defense
func get_resist() -> float      # WIS + bonus_armor_resist
func get_melee_atk() -> float   # floor(total("STR")×1.3) + floor(total("DEX")×0.25) + total("weapon_power")
func get_ranged_atk() -> float  # floor(total("STR")×1.3) + floor(total("LUC")×0.3) + floor(total("DEX")×0.2) + total("weapon_power")
func get_magic_atk() -> float   # floor(total("INT")×1.3) + floor(total("WIS")×0.2) + total("weapon_power")
func get_crit_chance() -> float # floor(total("LUC") × 0.2) — percent
func get_crit_damage() -> float # 1.5 + floor(total("LUC") × 0.0075) — multiplier

# Allocation helpers
func get_allocated_stats() -> Dictionary         # {STR, REC, INT, WIS, DEX, LUC}
func get_base_stats_value(key: String) -> int
func from_dict_to_base_stats(stats: Dictionary) -> void  # ← NEW: writes dict into STR/REC/… fields
func get_total(key: String) -> int               # base + bonus

# Bonus management
func add_stat_bonus(stat: String, value: int) -> void
func remove_stat_bonus(stat: String, value: int) -> void
func get_stats_bonus_dict() -> Dictionary
func get_primary_stats_breakdown() -> Dictionary
func get_secondary_stats_breakdown() -> Dictionary
```

### `AttackData` (`attack_data.gd`)
```gdscript
class_name AttackData
extends Resource

@export var anim_name: String = ""
@export var damage: float = 10.0
@export var combo_window: float = 1.2  # seconds to chain next hit
```

### `EnemyParams` (`enemy_params.gd`)
```gdscript
class_name EnemyParams
extends Resource

@export var enemy_name: String = "Enemy"
@export var enemy_avatar: Texture2D
@export var max_health: float = 100.0
@export var speed: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 70.0
@export var attack_cooldown: float = 2.2
@export var defense: float = 0.0
@export var resistance: float = 0.0
@export var xp_reward: int = 25
@export var custom_db_item_objects: Array[DataItem] = []
```

### Item System (`resources/items/`)
Inheritance chain:
```
DataItem  →  EquipableItem
          →  ConsumableItem
          →  Gem (extends Item / DataItem)

Legacy (DEPRECATED): Item, Equipable, Weapon, Armor, Consumable, Potion
```

#### `DataItem` (base — `data_item.gd`)
```gdscript
class_name DataItem
extends Resource

@export var item_id: String = ""
@export var item_name: String = ""
@export var price: int = 0
@export var grid_coordinate: Vector2 = Vector2.ZERO

func get_item_texture() -> AtlasTexture
```

#### `EquipableItem` (`equipable_item.gd`)
```gdscript
class_name EquipableItem
extends DataItem

enum EquipmentCategory { WEAPON, ARMOR, ACCESSORY }
enum ArmorType { SHIELD, CHEST, HEAD, LEGS_FEET, FEET, RING, NECKLACE }
enum WeaponType { DAGGER, SWORD, TWO_HANDED_SWORD, MELEE, TOOL_MELEE, AXE, TOOL_AXE, TWO_HANDED_AXE, MACE, TWO_HANDED_MACE, BOW, CROSSBOW, THROWING, POLEARM, STAFF, WAND }

@export var equipment_type: String = ""
@export var player_class: String = "ALL"
@export var required_level: int = 1
@export var base_damage: int = 0
@export var base_defense: int = 0
@export var upgrade_level: int = 0
@export var tradable: bool = true
@export var gems_slots_count: int = 0
@export var gems: Array[Gem] = []
@export var stat_bonus: Dictionary

func is_armor() -> bool
func get_item_texture() -> AtlasTexture
func get_gems() -> Array[Gem]
func get_effective_stats_breakdown() -> Dictionary
func get_gems_stats_bonus() -> Dictionary
```

#### `ConsumableItem` (`consumable_item.gd`)
```gdscript
class_name ConsumableItem
extends DataItem

enum ConsumableType { POTION, POISON }

@export var heal_amount: int = 0
@export var potion_type: String = "HEALTH"
```

#### `Gem` (`gem.gd`)
```gdscript
class_name Gem
extends Item

enum GemType { RUBY, SAPPHIRE, EMERALD, TOPAZ, AMETHYST, DIAMOND }

@export var gem_type: GemType
@export var gem_level: int = 1           # 1–3
@export var DEX: Array[float] = []
@export var STR: Array[float] = []
@export var LUC: Array[float] = []
@export var INT: Array[float] = []
@export var WIS: Array[float] = []
@export var REC: Array[float] = []

func get_dex_bonus() -> float
func get_str_bonus() -> float
func get_luc_bonus() -> float
func get_int_bonus() -> float
func get_wis_bonus() -> float
func get_rec_bonus() -> float
```

---

## HUD / UI Architecture (`in_game_ui.gd`, `stats_ui.gd`)

`InGameUI` has `process_mode = Node.PROCESS_MODE_ALWAYS` — UI stays active even when the game tree is paused.

**Tabs in HUD Panel (`TabContainer`):**
| Tab | Scene Node | Contents |
| :--- | :--- | :--- |
| **Stats** | `StatsPanel` | `StatContainer` rows (one per stat in `STAT_NAMES_NO_FLT`), points label, Save/Cancel buttons — managed by `StatsUI` |
| **Inventory** | `InventoryPanel` | 56 `InventorySlot` instances in a `GridContainer` |
| **Equipements** | `EquipementsPanel` | 9 wired `EquipementSlot` nodes |

**Potions Section (`$PotionsContainer`):**
Contains `health_potion_slot` and `mana_potion_slot` (`PotionSlot` instances).

**HUD toggle:** `PanelButton` (TextureButton) toggles `hud.visible`. Uses `openTexture` / `closeTexture` exports.

**Lootable items panel** (`$Control/LootableItemsTable`): Separate overlay. Contains a `GridContainer` with 20 `LootableItemSlot` instances. Pick All, Pick Selected, Cancel buttons.

**Popup tooltips:** Instantiated under `$Popups (Node2D)`. Only one tooltip active at a time (guarded by `item_table_details_instance` reference check).

### `StatsUI` (`stats_ui.gd`, `class_name StatsUI`, extends `Control`)
Dedicated UI controller for all stats-related display. Owned by `InGameUI`, which passes node references in via `setup_ui_references()`.

**Responsibilities:**
- Manages Hero HUD bars: `hp_bar`, `mana_bar`, `level_progress_bar`, `hp_label`, `mana_label`, `level_label`, `hero_avatar`.
- Manages Stats Panel: `stats_container` (VBoxContainer), `stats_points_label`, `save_stats_button`, `cancel_stats_button`.
- **Smooth tweening:** HP, MP, and XP bar updates animate with `Tween` (0.2s TRANS_SINE/EASE_OUT for HP/MP, 0.3s for XP).

**Signal connections (wired in `setup_ui_references()`):**
| Signal | Handler |
| :--- | :--- |
| `EventBus.stats_updated(stats_data)` | `update_stats(stats_data)` → updates panel + hero HUD |
| `EventBus.hero_hp_changed(current, max)` | `_on_hero_hp_changed` → smooth HP bar + label |
| `EventBus.hero_mp_changed(current, max)` | `_on_hero_mp_changed` → smooth MP bar + label |
| `EventBus.hero_xp_changed(current, total)` | `_on_hero_xp_changed` → smooth XP bar |
| `EventBus.stat_points_available_changed(n)` | `_on_stat_points_available_changed` → `update_stats_panel()` |
| `EventBus.level_up` | `_on_level_up` → updates level label and XP bar max |
| `EventBus.update_hero_avatar_texture` | `on_hero_avatar_texture` |

---

## Coding Standards & Virtual Functions

The project enforces the official GDScript file structure across all `.gd` scripts with `##` doc comments. Order:
`extends` → `class_name` → `signals` → `constants` → `exports` → `public/onready vars` → `built-in overrides` → `public methods` → `virtual methods` → `private methods` → `signal handlers`.

Section headers use the pattern: `# ─── Section Name ───...`.

All entities use a **Virtual Functions Override Pattern** to keep state machine code decoupled from concrete class logic:

| Function | Override Location | Base Class | Purpose |
| :--- | :--- | :--- | :--- |
| `_move()` | `Player.gd`, `Enemy.gd` | `Character.gd` | Physics movement (`velocity = dir * speed`) + travel run animation |
| `_idle()` | `Player.gd`, `Enemy.gd` | `Character.gd` | Zero velocity + travel idle animation |
| `_play_movement_animation()` | `Player.gd`, `Goblin.gd` | `Character.gd` | Sets `parameters/run/blend_position` on the AnimationTree |
| `_play_idle_animation()` | `Player.gd`, `Goblin.gd` | `Character.gd` | Sets `parameters/idle/blend_position` on the AnimationTree |
| `_attack()` | `Player.gd`, `Enemy.gd` | `Combatant.gd` | Start combo or trigger attack cooldown timer |
| `_die()` | `Player.gd`, `Enemy.gd` | `Combatant.gd` | `queue_free()` |
| `_on_damage_received()` | `Player.gd`, `Enemy.gd` | `Combatant.gd` | Hit flash, UI update, transition to DeadState |
| `_get_attack_damage()` | `Player.gd`, `Enemy.gd` | `Combatant.gd` | Returns current attack damage (stat-based for player, `attack_damage` for enemy) |
| `_get_defense()` | `Player.gd`, `Enemy.gd` | `Combatant.gd` | `StatsData.get_stats().get_def()` for player; `enemy_params.defense` for enemy |
| `_play_attack_animation()` | `Player.gd`, `Goblin.gd` | `Combatant.gd` / `Enemy.gd` | Sets attack blend position, travels to attack node |
| `_interact()` | Custom NPCs | `NPC.gd` | Virtual method for non-combat NPC interaction |

`take_damage(amount)` in `Combatant.gd` applies defense reduction: `reduced = max(1.0, amount - _get_defense())`.

---

## Essential Developer Rules

1.  **Await Safely:** Always check `is_instance_valid(actor)` after any `await get_tree().create_timer(...).timeout` inside state scripts or character methods. The actor may be freed while the timer runs (e.g., enemy killed during attack cooldown).
2.  **Top-Level Projectiles:** `set_as_top_level(true)` must be called on projectile instances before positioning them. This detaches them from the shooter's transform hierarchy so they fly straight regardless of shooter movement.
3.  **State Machine Transitions:** Use lowercase string keys (e.g., `transitioned.emit("enemychasestate")`). The `StateMachine` calls `.to_lower()` on all lookups. Do not use enums for state transitions.
4.  **Hitbox Toggling:** Enable/disable `CollisionShape2D` nodes on Hitboxes exclusively from AnimationPlayer timeline tracks. Never enable hitboxes in persistent `_process`/`_physics_process` scripts.
5.  **Scene Inheritance:** All subclass scenes (Warrior, Archer, Mage, Goblin) must be **Inherited Scenes** from their parent template (`Player.tscn` or `Enemy.tscn`) to preserve node configurations.
6.  **Item Drop-back:** Use `GameManager.drop_item(item)` to re-spawn items. Do not add `drop.tscn` instances directly to the scene tree from UI scripts.
7.  **Equipment Validation:** Always validate `player_type` via `GameManager._on_equip_item()` (triggered by `EventBus.equip_item`). Never equip items directly from UI scripts.
8.  **Equipment Keys:** `PlayerData.__equipable_items` uses string keys: `Armor.ArmorType.keys()[item.armor_type]` for armors, `"WEAPON"` for weapons. These must match exactly: `HELMET`, `CHEST`, `GLOVES`, `BOOTS`, `SHIELD`, `RING`, `AMULET`, `CLOAK`, `WEAPON`, `PET`.
9.  **Rarity/Rarety Typo:** The codebase consistently spells `Rarity` as `Rarety` (both the enum name `Item.Rarety` and the property `item.rarety`). Match this spelling in all new code to avoid type mismatches.
10. **Class Stats are Duplicated:** `CharacterClass.get_class_stats()` returns `base_stats` — `StatsData.initialize_from_character_stats()` duplicates this instance. After any equipment change, call `player_ref.character_class.set_class_stats(StatsData.get_stats())` to persist back to the class resource.
11. **StateMachine awaits owner.ready:** State nodes access `actor` and `state_machine` via `@onready`. This works because `StateMachine._ready()` itself `await owner.ready` before entering any states. Do not reference `actor` in state `_init()` or before the state machine is ready.
12. **Character debug Label:** `Character.gd` has an `@onready var label: Label = $Label` that updates each `_process` frame to display the current state name. This is a development aid — keep the `Label` node in all character scenes.
13. **Stats Access Pattern:** Always read live stats through `StatsData.get_stats()` (returns the `CharacterStats` resource). Never hold a long-lived reference to the `CharacterStats` instance across frames — it could be replaced on re-initialization.
14. **StatsManager is NOT an autoload:** `StatsManager` is a plain `Node` class instantiated at `GameManager.stats_manager`. Do not reference it as a global. Call `StatsManager` methods only from `GameManager` signal handlers or via `EventBus` signals.
15. **HP/MP Signal Flow:** When player takes damage, emit `EventBus.hero_hp_changed(current_hp, max_hp)` — **not** `stats_updated`. `hero_hp_changed` triggers the smooth tween animation in `StatsUI`. `stats_updated` is for full stat panel refreshes (allocation, equipment changes, level up). Mixing them causes animation glitches.
