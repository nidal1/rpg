# CLAUDE.md — 2D Action RPG (Godot 4)

## Project Overview
A 2D Action RPG with a dark fantasy, Moroccan, and Arabic folklore theme. Medium scope (~3-4 hours gameplay) built natively in **Godot 4.x** using **GDScript**.

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
Character.gd (Character)     → Base entity: health/mana stats, virtual hooks, take_damage (damage reduction via _get_defense())
  ├── Player.gd (Player)     → Input, combo management, movement, hit flashing, PickableDetection callbacks
  │     ├── Warrior.gd       → Melee: loads warrior.tres in _ready(), handles Hitbox area_entered → take_damage
  │     ├── Archer.gd        → Ranged: loads archer.tres in _ready(), targets enemies, spawns Arrow projectiles
  │     └── Mage.gd          → Ranged: loads mage.tres in _ready(), targets enemies, spawns WaterBullet projectiles
  └── Enemy.gd (Enemy)       → Base AI: NavigationAgent2D pathfinding, wander/chase movement, item dropping, HP bar UI
        └── Goblin.gd        → Melee enemy: animation blending, Hitbox area_entered → take_damage
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
*   **State (`state.gd`):** Abstract base class with lifecycle hooks `enter()`, `exit()`, `handle_input()`, `update()`, `physics_update()`. References `actor: Character` (owner) and `state_machine: StateMachine` (parent) via `@onready`.
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
| `EnemyWanderState` | `enemywanderstate` | Picks a random cardinal direction and navigates to that wander position. Returns to idle on arrival. |
| `EnemyPatrolState` | `enemypatrolstate` | Navigates enemy back to its `spawn_position` if it wandered too far or lost aggro. |
| `EnemyRunState` | `enemyrunstate` | Basic running state delegating to `actor._move()`. |
| `EnemyChaseState` | `enemychasestate` | Updates `NavigationAgent2D` to track player. Leashes to `MAX_DISTANCE_TO_SPAWN_LOCATION` (700 px). Transitions to attack when in range. |
| `EnemyAttackState` | `enemyattackstate` | Disables velocity, triggers cooldowned attack animation. Re-evaluates target position after each attack. |
| `EnemyDeadState` | `enemydeadstate` | Disables movement, triggers death animation, alerts spawning system to queue respawn. |

---

## Dynamic Gameplay Systems

### Lootable Items (Loot & Pickup)
*   **Naming Convention:** All dropped and picked items follow the `Lootable Item` convention in UI and logic.
*   **`DropItem` (`drop.gd`, `Area2D`):** Physical world representation of a dropped item. Fields: `item: Item`, `despawn_time: float = 30.0`. Starts a `DropCD` timer on `_ready()` and `queue_free()`s on timeout. Belongs to the `pickable` group.
*   **Player Detection:** Player's `PickableDetection` (Area2D) detects overlapping `DropItem` nodes. On enter: `EventBus.lootable_item_added.emit(item)`. On exit: `EventBus.lootable_item_removed.emit(item)`.
*   **UI Integration:** `InGameUI` catches signals, populates `LootableItemSlot` panels in a `GridContainer` (up to 20 slots). Players can multi-select slots to pick up, triggering `EventBus.selected_lootable_items_picked_up`.
*   **`LootableItemSlot` state:** Has three visual states (`normal`, `hover`, `pressed`) implemented via `StyleBoxFlat` border-color overrides.

### Inventory System (`inventory_slot.gd`, `in_game_ui.gd`)
Full 56-slot grid-based inventory in the **Inventory Tab** of the HUD panel.
*   **`InventorySlot` (Panel):** Holds one `Item`. Displays icon via `TextureRect`. Right-click opens `PopupMenu` with:
    *   **Equip** — visible only if item `is Equipable`. Emits `EventBus.equip_item(inventory_slot)`.
    *   **Use** — stub (prints "use item").
    *   **Drop** — emits `EventBus.item_dropped_from_inventory(item)`, clears slot.
*   **Hover tooltip:** `mouse_entered` emits `EventBus.show_item_table_details(item)`. `mouse_exited` emits `EventBus.hide_item_table_details()`.
*   **Item Drop-back Flow:** `GameManager._on_item_dropped_from_inventory()` → `drop_item(item)` → gets first `enemies_spawner` group node's drop zone → places `drop.tscn` at randomized offset (`drop_range = 50.0`) near player.

### Equipment System (`equipement_slot.gd`, `in_game_ui.gd`, `player_data.gd`)
Full 10-slot equipment panel in the **Equipements Tab** of the HUD. Each slot is an `EquipementSlot` (Panel) with a `placeholder_image`, an item `TextureRect`, and a right-click **Unequip** context menu.

**Equipment Slots (keyed by `slot_key` string and `PlayerData.__equipable_items` dictionary key):**
| Slot Key | Type | UI Node (in `InGameUI`) |
| :--- | :--- | :--- |
| `HELMET` | `Armor.ArmorType.HELMET` | `helmet_slot` |
| `CHEST` | `Armor.ArmorType.CHEST` | `chest_slot` |
| `BOOTS` | `Armor.ArmorType.BOOTS` | `boots_s_lot` *(note: typo in node name)* |
| `SHIELD` | `Armor.ArmorType.SHIELD` | `shield_slot` |
| `RING` | `Armor.ArmorType.RING` | `ring_slot` |
| `AMULET` | `Armor.ArmorType.AMULET` | `amulet_slot` |
| `CLOAK` | `Armor.ArmorType.CLOAK` | `cloak_slot` |
| `WEAPON` | `Weapon` | `weapon_slot` |
| `GLOVES` | *(reserved — no UI slot wired)* | — |
| `PET` | *(reserved)* | `pet_slot` |

**Equip Flow:**
1. Right-click `InventorySlot` → select "Equip" → `EventBus.equip_item(inventory_slot)`.
2. `GameManager._on_equip_item()`: validates `player_type` (`ALL` or matching class).
3. Determines `item_type` key: `Armor.ArmorType.keys()[item.armor_type]` for armor, `"WEAPON"` for weapons.
4. If slot empty: `PlayerData.add_equipable_item(item)` → updates `__base_stats` weapon/armor values → `EventBus.item_equipped.emit(inventory_slot)`.
5. If slot occupied (swap): reads old item, `add_equipable_item(new)`, `add_inventory_item(old)`, emits `item_equipped`, then rewrites the `InventorySlot` with old item for the UI swap.
6. `InGameUI._on_item_equipped()` routes to the correct `EquipementSlot.set_item()` and clears the `InventorySlot`.

**Unequip Flow:**
1. Right-click `EquipementSlot` → "Unequip" → `EventBus.item_unequipped(item)`.
2. `GameManager._on_item_unequipped()`: `PlayerData.add_inventory_item(item)` + `PlayerData.remove_equipable_item(item)`.
3. `EventBus.items_added_to_inventory` emitted to refresh UI.

**Stat Effect of Equipment:**
`PlayerData.add_equipable_item()` / `remove_equipable_item()` directly mutates `__base_stats.weapon_power`, `__base_stats.armor_defense`, `__base_stats.armor_resist`. After equipping, `GameManager._on_equip_item()` calls `player_ref.character_class.set_class_stats(__base_stats)` to persist the change back to the class resource.

**Class Restriction:** `Equipable.player_type: CharacterClass.PlayerType`. `PlayerType.ALL` = any class. Otherwise must match `player_ref.character_class.player_type`.

### Item Tooltip / Table Details
Hovering an `InventorySlot` shows a floating popup with full item details:
*   `EventBus.show_item_table_details(item)` → `InGameUI._on_show_item_table_details()`:
    *   Instantiates `weapon_table_details_scene` (if `Weapon`) or `armor_table_details_scene` (if `Armor`).
    *   Adds to `$Popups` node. Calls `set_equipable_item(item)`. Positions near mouse, with viewport-edge clamping.
*   `EventBus.hide_item_table_details()` → frees the instance.
*   **`EquipableTableDetails` (base):** Shows name, class restriction, level, icon, category, rarity, description, gem slots.
*   **`WeaponTableDetails`:** Extends base; adds attack power label (orange if `upgrade_level > 0`).
*   **`ArmorTableDetails`:** Extends base; adds defense and resistance labels (orange if respective upgrade > 0).

### Projectiles (`arrow.gd`, `water_bullet.gd`)
*   Both extend `Area2D`. Fields: `speed`, `max_distance`, `direction`, `velocity`, `distance_traveled`.
*   `Arrow` emits `arrow_hit(area)`. `WaterBullet` emits `bullet_hit(area)`.
*   **Lifecycle:** Instantiated as top-level (`set_as_top_level(true)`), added to `arrows_container` / `bullets_container`. Auto `queue_free()` when `distance_traveled >= max_distance` or on obstacle hit.
*   **Spawning position:** Both `Archer` and `Mage` use a scene-internal `%ArrowSpawningPosition` / `%BulletSpawningPosition` Marker2D. Position offset is mirrored by `last_facing_dir`.
*   **Targeting:** The projectile always fires toward the `target`'s `Hurtbox` node global position (if it exists), else the target body's position. Falls back to `last_facing_dir` if no target.
*   **Trigger:** AnimationPlayer calls a method in the script (e.g., `_on_animation_editor_arrow_attack()`), which emits a private signal (`_animation_editor_arrow_attack`), which is connected to the actual spawning handler. This double-indirection lets the animator trigger projectiles at an exact frame.
*   **Range:** `attack_range = 300.0` for Archer, `attack_range = 500.0` for Mage. Projectile `max_distance` is computed as `attack_range - POSITION_OFFSET.x - SPRITE_WIDTH/2`.

### Enemies Spawner (`enemies_spawner.gd`)
*   **Type:** `Node2D`, belongs to the `enemies_spawner` group.
*   **Exports:** `spawn_point: Marker2D`, `enemies: Array[PackedScene]`, `spawn_circle_radius: float = 100.0`, `respawn_cd: float = 60.0`, `wander_cd_time: float = 20.0`.
*   **`%DropZone` (Node2D):** Child node used as parent for all `DropItem` instances spawned by enemies under this spawner.
*   **Spawning:** On `_ready()`, spawns one enemy instance per entry in `enemies` array. `_spawn_enemy()` picks a random enemy scene, instantiates it, adds as child, and emits `EventBus.enemy_spawned`.
*   **Respawn:** `remove_enemy(enemy)` starts a `respawn_cd` timer then calls `_spawn_enemy()`.
*   **Drop Cleanup:** Connects to `EventBus.selected_lootable_items_picked_up` → `remove_selected_drops()` queue-frees matching `DropItem` children from `DropZone`.
*   **`get_drop_zone()` → Node:** Used by `GameManager.spawn_enemy_items()` and `drop_item()` to locate the correct parent for new drops.

### Stat Allocation System (`player_data.gd`, `game_manager.gd`, `in_game_ui.gd`)
*   **5 points per level-up** (`POINTS_STATS_PER_LEVEL = 5`).
*   **Working copy (`__allocated_stats`):** Dict seeded from class base stats via `from_base_stats_to_dict()` on init. Updated by `add_stat_point()` / `sub_stat_point()`.
*   **Backup copy (`__temp_allocated_stats`):** Stores the last committed state.
*   **`save_stats()`:** Copies working → backup. Sets `allocate_point_saved = true` if `__stat_points_available <= 0`.
*   **`cancel_stats()`:** Reverts working from backup. Sets `allocate_point_saved = false`.
*   **`allocate_point_saved`:** Blocks further point changes once all points are saved; reset on cancel or new level-up.
*   **XP:** Starts at 0, target is `75` XP for level 2. Each level-up scales target by `level_scaler = 1.2`.

---

## Global Autoloads (Singletons)

Autoload order in `project.godot`: `EventBus` → `GameManager` → `SaveManager` → `PlayerData`.

### `EventBus` (`event_bus.gd`)
Centralized signal broker. All signals carry `@warning_ignore("UNUSED_SIGNAL")`.

| Group | Signal | Payload |
| :--- | :--- | :--- |
| **UI/HUD** | `initialize_hero_stats_ui` | `cls: CharacterClass` |
| | `update_hero_avatar_texture` | `texture: Texture2D` |
| | `update_hp_bar_value` | `value: float` |
| | `update_mana_bar_value` | `value: float` |
| **Combat/Progression** | `enemy_died` | `enemy: Enemy` |
| | `enemy_spawned` | `enemy: Enemy, spawn_position: Vector2` |
| | `xp_changed` | `current: int` |
| | `level_up` | `new_level: int` *(emitted without arg from GameManager — default 0)* |
| **Stats Allocation** | `stat_allocated` | `stat_name: String` |
| | `stat_deallocated` | `stat_name: String` |
| | `stats_updated` | *(none)* |
| | `save_stats_points` | *(none)* |
| | `cancel_stats_points` | *(none)* |
| **Loot** | `lootable_item_added` | `item: Item` |
| | `lootable_item_removed` | `item: Item` |
| | `display_lootable_item_hover_info` | `item: Item` |
| | `hide_lootable_item_hover_info` | `item: Item` |
| | `selected_lootable_items_picked_up` | `slots: Array[Item]` |
| **Inventory** | `items_added_to_inventory` | `slots: Array[Item]` |
| | `items_removed_from_inventory` | `slots: Array[Item]` |
| | `item_dropped_from_inventory` | `slot: Item` |
| **Item Details** | `show_item_table_details` | `item: Item` |
| | `hide_item_table_details` | *(none)* |
| **Equipment** | `equip_item` | `inventory_slot: InventorySlot` |
| | `item_equipped` | `inventory_slot: InventorySlot` |
| | `item_unequipped` | `item: Equipable` |
| | `switch_equipements` | *(none — reserved)* |

### `PlayerData` (`player_data.gd`)
Central data store. Constants: `STAT_NAMES = ["STR","REC","INT","WIS","DEX","LUC"]`, `POINTS_STATS_PER_LEVEL = 5`.

**`initialize(cls: CharacterClass)`:** Duplicates `cls.get_class_stats()` into `__base_stats`, then seeds both `__allocated_stats` and `__temp_allocated_stats` from `from_base_stats_to_dict()` (which includes `weapon_power`, `armor_defense`, `armor_resist`).

**Stat formulas (all read `__base_stats.STR` etc. directly — uppercase keys):**
| Method | Formula |
| :--- | :--- |
| `get_melee_atk()` | `floor(STR × 1.3) + floor(DEX × 0.25) + weapon_power` |
| `get_ranged_atk()` | `STR + (LUC × 0.3) + (DEX × 0.2) + weapon_power` |
| `get_magic_atk()` | `floor(INT × 1.3) + floor(WIS × 0.2) + weapon_power` |
| `get_max_hp()` | `100.0 + (REC × 5.0)` |
| `get_max_mp()` | `50.0 + (WIS × 5.0)` |
| `get_def()` | `REC + armor_defense` |
| `get_resist()` | `WIS + armor_resist` |
| `get_crit_chance()` | `LUC × 0.2` (percent) |
| `get_crit_damage()` | `1.5 + (LUC × 0.0075)` (multiplier) |

**`__equipable_items` dictionary (10 keys):** `HELMET`, `CHEST`, `GLOVES`, `BOOTS`, `SHIELD`, `WEAPON`, `RING`, `AMULET`, `CLOAK`, `PET` — all default `null`.

**Equipment stat mutation:**
*   `add_equipable_item(Weapon)`: adds `item.base_attack_power` to `__base_stats.weapon_power`.
*   `add_equipable_item(Armor)`: adds `item.base_defense` to `__base_stats.armor_defense`, `item.base_resist` to `__base_stats.armor_resist`.
*   `remove_equipable_item(Weapon)`: subtracts `item.base_attack_power` from `__base_stats.weapon_power`.
*   `remove_equipable_item(Armor)`: subtracts `item.base_defense` and `item.base_resist` from base stats.

**Accessors for base stat fields:**
`get_base_weapon_power()`, `get_base_armor_defense()`, `get_base_armor_resist()` and corresponding setters.

### `GameManager` (`game_manager.gd`)
Orchestrates top-level game flow. Key public variables: `player_ref: Character`, `level_scaler: float = 1.2`, `drop_range: float = 50.0`.

*   **`register_player(player)`:** Sets `player_ref`, calls `PlayerData.initialize(player.character_class)`, emits `EventBus.initialize_hero_stats_ui`.
*   **`add_xp(amount)`:** Increments XP, emits `xp_changed`, calls `level_up()` if threshold met.
*   **`level_up()`:** Increments `player_level`, calls `PlayerData.update_available_points()`, `scaling_level_up()`, emits `level_up`.
*   **`spawn_enemy_items(enemy)`:** Gets drop zone from `enemy.get_parent().get_drop_zone()`, calls `enemy._drop_item()`, adds drops at randomized positions.
*   **`drop_item(item)`:** Loads `drop.tscn`, gets the first `enemies_spawner` group node's drop zone, places item near `player_ref.global_position` ± `drop_range`.
*   **`randomize_drop_position(position, range)`:** Returns `position + Vector2(randf_range(-range, range), randf_range(-range, range))`.

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
│   │   └── item/               → armor_table_details.tscn, weapon_table_details.tscn,
│   │                              item_stats_row.tscn, gem_panel.tscn
│   └── components/             → (reserved)
├── scripts/
│   ├── autoloads/              → event_bus.gd, game_manager.gd, player_data.gd, save_manager.gd
│   ├── entities/               → character.gd, player.gd, enemy.gd, warrior.gd, archer.gd, mage.gd,
│   │   │                         goblin.gd, arrow.gd, water_bullet.gd, enemies_spawner.gd,
│   │   │                         in_game_ui.gd, lootable_item_slot.gd, inventory_slot.gd,
│   │   │                         equipement_slot.gd, stat_container.gd,
│   │   │                         equipable_table_details.gd, armor_table_details.gd,
│   │   │                         weapon_table_details.gd, gem_panel.gd, item_stats_row.gd
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
    └── items/                  → item.gd, equipable.gd, weapon.gd, armor.gd, gem.gd
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

```json
{
  "weapons_database": {
    "iron_tier":            [ { "id": "w_ir_XX", "name": "...", "type": "...", "grid_coordinate": {...}, "required_level": N, "base_damage": N } ],
    "gold_tier":            [ ... ],
    "azure_tier":           [ ... ],
    "mythic_and_rare_tier": [ ... ]
  },
  "armors_database": {
    "shields_and_early_sets":       [ { "id": "a_sh_XX", "name": "...", "type": "Shield/Chest/...", "grid_coordinate": {...}, "required_level": N, "base_defense": N } ],
    "heavy_plate_tier":             [ ... ],
    "mage_and_rogue_cloth_tier":    [ ... ],
    "dark_fantasy_and_exotic_tier": [ ... ],
    "crystals_shields_and_boots":   [ ... ],
    "accessories_and_rings":        [ { ..., "bonus_mana": N } or { ..., "bonus_attack": N } ]
  }
}
```

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
@export var max_health: float = 100.0
@export var max_mana: float = 50.0
@export var speed: float = 300.0
@export var combo_chain: Array[AttackData] = []
@export var base_stats: CharacterStats

func get_class_stats() -> CharacterStats  # returns base_stats.duplicate(true)
func set_class_stats(stats: CharacterStats) -> void  # sets base_stats = stats.duplicate(true)
```
> `set_class_stats()` is called by `GameManager._on_equip_item()` after stat updates to persist equipment changes back to the class resource.

### `CharacterStats` (`character_stats.gd`)
```gdscript
class_name CharacterStats
extends Resource

@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var DEX: int = 0
@export var WIS: int = 0
@export var LUC: int = 0

# Mutated directly by PlayerData equipment methods:
@export var weapon_power: float = 0.0
@export var armor_defense: float = 0.0
@export var armor_resist: float = 0.0
```
> **Note:** Field names are uppercase abbreviated (`STR`, `REC`, etc.), not `strength`/`recovery`. `PlayerData.get_total()` reads them directly as `__base_stats.STR`, `__base_stats.REC`, etc.

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
@export var defense: float = 0.0       # used by Enemy._get_defense()
@export var resistance: float = 0.0    # reserved
@export var xp_reward: int = 25
@export var drop_list: Array[Item] = []
```

### Item System (`resources/items/`)
Inheritance chain:
```
Item  →  Equipable  →  Weapon
                   →  Armor
     →  Gem
```
> `Gem extends Item` directly (not `Equipable`). Gems are socketed into `Equipable.gems`.

#### `Item` (base — `item.gd`)
```gdscript
class_name Item
extends Resource

enum ItemType { EQUIPABLE, CONSUMABLE, QUEST, ENCHANTMENT }
enum Rarety   { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }   # ← "Rarety" (typo in codebase)

@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType
@export var rarety: Rarety = Rarety.COMMON                  # ← "rarety" (typo in codebase)
```
> `ItemType.EQUIPABLE` is used for all wearable items. The concrete subclass (`Weapon`/`Armor`) determines behavior.

#### `Equipable` (`equipable.gd`)
```gdscript
class_name Equipable
extends Item

@export var player_type: CharacterClass.PlayerType = CharacterClass.PlayerType.ALL
@export var upgrade_level: int = 0
@export var tradable: bool = true
@export var gems_slots_count: int        # number of available gem slots
@export var gems: Array[Gem] = []        # currently socketed gems (max gems_slots_count)
@export var level: int = 1               # required player level to equip

func get_gems() -> Array[Gem]
func _add_gem(gem: Gem) -> void          # private; enforces gems_slots_count cap
func _remove_gem(gem: Gem) -> void
```

#### `Weapon` (`weapon.gd`)
```gdscript
class_name Weapon
extends Equipable

enum WeaponType { SWORD, AXE, BOW, STAFF, DAGGER }

@export var weapon_type: WeaponType
@export var base_attack_power: float = 10.0

func get_total_attack_power() -> float   # base_attack_power + sum(gem.get_atk_bonus()), floored to 1 decimal
```

#### `Armor` (`armor.gd`)
```gdscript
class_name Armor
extends Equipable

enum ArmorType { HELMET, CHEST, BOOTS, GLOVES, SHIELD, RING, AMULET, CLOAK }

@export var armor_type: ArmorType
@export var base_defense: float = 5.0
@export var base_resist: float = 0.0
@export var upgrade_resistance_level: int = 0

func get_total_defense() -> float        # base_defense + sum(gem.get_def_bonus())
func get_total_resistance() -> float     # base_resist + sum(gem.get_resist_bonus())
```
> `ArmorType` string keys (via `Armor.ArmorType.keys()[item.armor_type]`) are used as `PlayerData.__equipable_items` dictionary keys.

#### `Gem` (`gem.gd`)
```gdscript
class_name Gem
extends Item

enum GemType { RUBY, SAPPHIRE, EMERALD, TOPAZ, AMETHYST, DIAMOND }

@export var gem_type: GemType
@export var gem_level: int = 1           # 1–3

# Per-level bonus arrays [lv1_bonus, lv2_bonus, lv3_bonus]
@export var atk_bonus: Array[float] = []
@export var def_bonus: Array[float] = []
@export var hp_bonus: Array[float] = []
@export var mp_bonus: Array[float] = []
@export var crit_bonus: Array[float] = []

func get_atk_bonus() -> float            # atk_bonus[gem_level - 1], 0.0 if empty
func get_def_bonus() -> float
func get_hp_bonus() -> float
func get_mp_bonus() -> float
func get_crit_bonus() -> float
func get_resist_bonus() -> float         # always returns 0.0 (stub)
```

---

## HUD / UI Architecture (`in_game_ui.gd`)

`InGameUI` has `process_mode = Node.PROCESS_MODE_ALWAYS` — UI stays active even when the game tree is paused.

**Tabs in HUD Panel (`TabContainer`):**
| Tab | Scene Node | Contents |
| :--- | :--- | :--- |
| **Stats** | `StatsPanel` | `StatContainer` rows (one per stat in `STAT_NAMES`), points label, Save/Cancel buttons |
| **Inventory** | `InventoryPanel` | 56 `InventorySlot` instances in a `GridContainer` |
| **Equipements** | `EquipementsPanel` | 9 wired `EquipementSlot` nodes |

**HUD toggle:** `PanelButton` (TextureButton) toggles `hud.visible`. Uses `openTexture` / `closeTexture` exports.

**Lootable items panel** (`$Control/LootableItemsTable`): Separate overlay (not a tab). Contains a `GridContainer` with 20 `LootableItemSlot` instances. Has Pick All, Pick Selected, Cancel buttons. Item count label at `$Control/LootableItems/LootableItemsNotiication/ItemsLabel`.

**Popup tooltips:** Instantiated under `$Popups (Node2D)`. Only one tooltip active at a time (guarded by `item_table_details_instance` reference check).

---

## Coding Standards & Virtual Functions

The project enforces the official GDScript file structure across all `.gd` scripts with `##` doc comments. Order:
`extends` → `class_name` → `signals` → `constants` → `exports` → `public/onready vars` → `built-in overrides` → `public methods` → `virtual methods` → `private methods` → `signal handlers`.

Section headers use the pattern: `# ─── Section Name ───...`.

All entities use a **Virtual Functions Override Pattern** to keep state machine code decoupled from concrete class logic:

| Function | Override Location | Purpose |
| :--- | :--- | :--- |
| `_move()` | `Player.gd`, `Enemy.gd` | Physics movement (`velocity = dir * speed`) + travel run animation |
| `_idle()` | `Player.gd`, `Enemy.gd` | Zero velocity + travel idle animation |
| `_attack()` | `Player.gd`, `Enemy.gd` | Start combo or trigger attack cooldown timer |
| `_die()` | `Player.gd`, `Enemy.gd` | `queue_free()` |
| `_on_damage_received()` | `Player.gd`, `Enemy.gd` | Hit flash, UI update, transition to DeadState |
| `_get_attack_damage()` | `Player.gd`, `Enemy.gd` | Returns current attack damage (stat-based for player, `attack_damage` for enemy) |
| `_get_defense()` | `Player.gd`, `Enemy.gd` | `PlayerData.get_def()` for player; `enemy_params.defense` for enemy |
| `_play_movement_animation()` | `Player.gd`, `Goblin.gd` | Sets `parameters/run/blend_position` on the AnimationTree |
| `_play_idle_animation()` | `Player.gd`, `Goblin.gd` | Sets `parameters/idle/blend_position` on the AnimationTree |
| `_play_attack_animation()` | `Player.gd`, `Goblin.gd` | Sets attack blend position, travels to attack node |

`take_damage(amount)` in `Character.gd` applies defense reduction: `reduced = max(1.0, amount - _get_defense())`.

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
10. **Class Stats are Duplicated:** `CharacterClass.get_class_stats()` returns `base_stats.duplicate(true)` — a deep copy. `PlayerData.initialize()` stores this copy and mutates it freely. Call `set_class_stats()` on the class resource to persist stat changes from equipment back to the class.
11. **StateMachine awaits owner.ready:** State nodes access `actor` and `state_machine` via `@onready`. This works because `StateMachine._ready()` itself `await owner.ready` before entering any states. Do not reference `actor` in state `_init()` or before the state machine is ready.
12. **Character debug Label:** `Character.gd` has an `@onready var label: Label = $Label` that updates each `_process` frame to display the current state name. This is a development aid — keep the `Label` node in all character scenes.
