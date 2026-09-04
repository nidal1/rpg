# CLAUDE.md — 2D Action RPG (Godot 4)

## Project Overview
A 2D Action RPG with a dark fantasy, Moroccan, and Arabic folklore theme. Medium scope (~3-4 hours gameplay) built natively in **Godot 4.x** using **GDScript**. The codebase consists of 52 modular GDScript files implementing state machines, dynamic equipment/gems/potion systems, inventory, stat allocations, pathfinding AI, and custom UI components.

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
Character.gd (CharacterBody2D)  → Base entity: health/mana stats, virtual hooks, take_damage (defense reduction)
  ├── Player.gd (Player)       → Input, combo management, movement, hit flashing, PickableDetection callbacks
  │     ├── Warrior.gd         → Melee: loads warrior.tres in _ready(), handles Hitbox area_entered → take_damage
  │     ├── Archer.gd          → Ranged: loads archer.tres in _ready(), targets enemies, spawns Arrow projectiles
  │     └── Mage.gd            → Ranged: loads mage.tres in _ready(), targets enemies, spawns WaterBullet projectiles
  └── Enemy.gd (Enemy)         → Base AI: NavigationAgent2D pathfinding, wander/chase movement, item dropping, HP bar UI
        └── Goblin.gd          → Melee enemy: animation blending, Hitbox area_entered → take_damage
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
*   **`DropItem` (`drop.gd`, `Area2D`):** Physical world representation of a dropped item. Fields: `item: Item`, `despawn_time: float = 30.0`. Starts a `DropCD` timer on `_ready()` and `queue_free()`s on timeout. Belongs to the `pickable` group.
*   **Player Detection:** Player's `PickableDetection` (Area2D) detects overlapping `DropItem` nodes. On enter: `EventBus.lootable_item_added.emit(item)`. On exit: `EventBus.lootable_item_removed.emit(item)`.
*   **UI Integration:** `InGameUI` catches signals, populates `LootableItemSlot` panels in a `GridContainer` (up to 20 slots). Players can multi-select slots to pick up, triggering `EventBus.selected_lootable_items_picked_up`.
*   **`LootableItemSlot` state:** Has three visual states (`normal`, `hover`, `pressed`) implemented via `StyleBoxFlat` border-color overrides.

### Inventory System (`inventory_slot.gd`, `in_game_ui.gd`)
Full 56-slot grid-based inventory in the **Inventory Tab** of the HUD panel.
*   **`InventorySlot` (Panel):** Holds one `Item`. Displays icon via `TextureRect`. Right-click opens `PopupMenu` with:
    *   **Equip** — enabled if item is `Equipable` or `Consumable`. Emits `EventBus.equip_item(inventory_slot)`.
    *   **Use** — stub (prints "use item").
    *   **Drop** — emits `EventBus.item_dropped_from_inventory(item)`, clears slot.
*   **Hover tooltip:** `mouse_entered` emits `EventBus.show_item_table_details(item)`. `mouse_exited` emits `EventBus.hide_item_table_details()`.
*   **Item Drop-back Flow:** `GameManager._on_item_dropped_from_inventory()` → `drop_item(item)` → gets first `enemies_spawner` group node's drop zone → places `drop.tscn` at randomized offset (`drop_range = 50.0`) near player.

### Potions & Consumables System (`consumable.gd`, `potion.gd`, `potion_slot.gd`, `player_data.gd`)
*   **Item Hierarchy:** `Item` → `Consumable` → `Potion`.
*   **Types:** `Potion.PotionType` (`HEALTH_POTION`, `MANA_POTION`).
*   **Equip / Routing:** Right-clicking a potion in the inventory and selecting "Equip" triggers `GameManager._on_equip_item()`, which routes it to `PlayerData.add_potion(item)` and emits `EventBus.potions_added_to_list.emit(item)`.
*   **HUD Slot (`PotionSlot`):** Displays current potion icon and count. Right-click opens `PopupMenu` with:
    *   **Unequip** — emits `EventBus.potions_unequipped(potion)` → returns item to inventory.
    *   **Consume** — emits `EventBus.potions_consumed(potion)` → triggers potion effect.

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
2. `GameManager._on_equip_item()`: validates `player_type` (`ALL` or matching class: `WARRIOR`, `ARCHER`, `MAGE`, `PRIEST`).
3. Determines `item_type` key: `Armor.ArmorType.keys()[item.armor_type]` for armor, `"WEAPON"` for weapons.
4. If slot empty: `PlayerData.add_equipable_item(item)` → calls `PlayerData.calculate_equipement_stats_bonus(item, "equip")` → `EventBus.item_equipped.emit(inventory_slot)`.
5. If slot occupied (swap): `PlayerData.remove_equipable_item(old)` → `PlayerData.calculate_equipement_stats_bonus(old, "unequip")` → adds new item, updates stats, puts old item into inventory slot for UI swap.
6. `InGameUI._on_item_equipped()` routes to the correct `EquipementSlot.set_item()` and clears the `InventorySlot`.

**Stat Effect & Gem Bonuses:**
`PlayerData.calculate_equipement_stats_bonus()` processes `item.get_effective_stats_breakdown()`, combining base item stat bonuses and socketed gem bonuses into `__base_stats.add_stat_bonus()` / `remove_stat_bonus()`. Base weapon power, armor defense, and armor resistance are updated accordingly.

### Gem System (`gem.gd`, `gem_panel.gd`, `equipable.gd`)
*   **Gems Socketing:** `Equipable` supports up to `gems_slots_count` socketed gems (`gems: Array[Gem]`).
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
    *   Instantiates `weapon_table_details_scene` (if `Weapon`) or `armor_table_details_scene` (if `Armor`).
    *   Adds to `$Popups` node. Calls `set_equipable_item(item)`. Positions near mouse, with viewport-edge clamping.
*   `EventBus.hide_item_table_details()` → frees the instance.
*   **`EquipableTableDetails` (base):** Shows name, class restriction, level, icon, category, rarity, description, gem slots (`GemPanel` instances), and stat rows (`ItemStatsRow`).
*   **`WeaponTableDetails`:** Extends base; adds attack power label (orange `#ff5b00` if `upgrade_level > 0`).
*   **`ArmorTableDetails`:** Extends base; adds defense and resistance labels (orange `#ff5b00` if respective upgrade > 0).

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
*   **Drop Cleanup:** Connects to `EventBus.selected_lootable_items_picked_up` → `remove_selected_drops()` queue-frees matching `DropItem` children from `DropZone`.
*   **`get_drop_zone()` → Node:** Used by `GameManager.spawn_enemy_items()` and `drop_item()` to locate the correct parent for new drops.

### Stat Allocation System (`player_data.gd`, `game_manager.gd`, `in_game_ui.gd`)
*   **5 points per level-up** (`POINTS_STATS_PER_LEVEL = 5`).
*   **Stat Lists:** `STAT_NAMES = ["HP", "MP", "STR", "REC", "INT", "WIS", "DEX", "LUC"]`, `STAT_NAMES_NO_FLT = ["STR", "REC", "INT", "WIS", "DEX", "LUC"]`.
*   **Working copy (`__allocated_stats`):** Dict seeded from class base stats via `get_allocated_stats()` on init. Updated by `add_stat_point()` / `sub_stat_point()`.
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
| | `update_hero_stats_ui` | `stats: CharacterStats` |
| | `update_hero_avatar_texture` | `texture: Texture2D` |
| | `update_hp_bar_value` | `value: float` |
| | `update_mana_bar_value` | `value: float` |
| **Combat/Progression** | `enemy_died` | `enemy: Enemy` |
| | `enemy_spawned` | `enemy: Enemy, spawn_position: Vector2` |
| | `xp_changed` | `current: int` |
| | `level_up` | `new_level: int` *(emitted without arg from GameManager)* |
| **Stats Allocation** | `stat_allocated` | `stat_name: String` |
| | `stat_deallocated` | `stat_name: String` |
| | `stats_updated` | *(none)* |
| | `update_stats` | `stats: CharacterStats` |
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
| **Potions** | `potions_added_to_list` | `potion: Potion` |
| | `potions_unequipped` | `potion: Potion` |
| | `potions_consumed` | `potion: Potion` |

### `PlayerData` (`player_data.gd`)
Central data store. Manages levels, XP, stats allocation, equipment bonuses, inventory, lootable items, and potion lists (`HEALTH` & `MANA`).

**`initialize(stats: CharacterStats)`:** Gets deep copy instance of class stats, seeds `__allocated_stats` and `__temp_allocated_stats`.

**Stat formulas (evaluated on `CharacterStats` using `get_total(key)`):**
| Method | Formula |
| :--- | :--- |
| `get_melee_atk()` | `floor(total("STR") × 1.3) + floor(total("DEX") × 0.25) + total("weapon_power")` |
| `get_ranged_atk()` | `floor(total("STR") × 1.3) + floor(total("LUC") × 0.3) + floor(total("DEX") × 0.2) + total("weapon_power")` |
| `get_magic_atk()` | `floor(total("INT") × 1.3) + floor(total("WIS") × 0.2) + total("weapon_power")` |
| `get_max_hp()` | `100.0 + (REC + get_bonus_rec()) × 5.0 + get_bonus_max_hp()` |
| `get_max_mp()` | `50.0 + (WIS × 5.0) + get_bonus_max_mp()` |
| `get_def()` | `REC + get_bonus_armor_defense()` |
| `get_resist()` | `WIS + get_bonus_armor_resist()` |
| `get_crit_chance()` | `floor(total("LUC") × 0.2)` (percent) |
| `get_crit_damage()` | `1.5 + floor(total("LUC") × 0.0075)` (multiplier) |

**Equipment & Stat Bonus Management:**
*   `calculate_equipement_stats_bonus(equipement, operation="equip")`: updates `__base_stats` bonuses for effective breakdown stats, weapon power, armor defense, and armor resistance.
*   `__equipable_items` dictionary (10 keys): `HELMET`, `CHEST`, `GLOVES`, `BOOTS`, `SHIELD`, `WEAPON`, `RING`, `AMULET`, `CLOAK`, `PET`.

### `GameManager` (`game_manager.gd`)
Orchestrates top-level game flow. Key public variables: `player_ref: Character`, `level_scaler: float = 1.2`, `drop_range: float = 50.0`.

*   **`register_player(player)`:** Sets `player_ref`, calls `PlayerData.initialize(player.character_class.get_class_stats())`, emits `EventBus.initialize_hero_stats_ui`.
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
│   │   ├── potion_slot.tscn
│   │   └── item/               → armor_table_details.tscn, weapon_table_details.tscn,
│   │                              item_stats_row.tscn, gem_panel.tscn
│   └── components/             → (reserved)
├── scripts/
│   ├── autoloads/              → event_bus.gd, game_manager.gd, player_data.gd, save_manager.gd
│   ├── entities/               → character.gd, player.gd, enemy.gd, warrior.gd, archer.gd, mage.gd,
│   │   │                         goblin.gd, arrow.gd, water_bullet.gd, enemies_spawner.gd,
│   │   │                         in_game_ui.gd, lootable_item_slot.gd, inventory_slot.gd,
│   │   │                         equipement_slot.gd, potion_slot.gd, stat_container.gd,
│   │   │                         equipable_table_details.gd, armor_table_details.gd,
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

@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var DEX: int = 0
@export var WIS: int = 0
@export var LUC: int = 0

@export var __bonus_stats: Dictionary  # max_health, max_mana, STR, REC, INT, WIS, DEX, LUC, weapon_power, armor_defense, armor_resist

func get_instance() -> CharacterStats
func get_allocated_stats() -> Dictionary
func get_max_hp() -> float
func get_max_mp() -> float
func get_def() -> float
func get_resist() -> float
func get_melee_atk() -> float
func get_ranged_atk() -> float
func get_magic_atk() -> float
func get_crit_chance() -> float
func get_crit_damage() -> float
func add_stat_bonus(stat: String, value: int) -> void
func remove_stat_bonus(stat: String, value: int) -> void
func get_total(key: String) -> int
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
@export var drop_list: Array[Item] = []
```

### Item System (`resources/items/`)
Inheritance chain:
```
Item  →  Equipable  →  Weapon
                    →  Armor
      →  Consumable →  Potion
      →  Gem
```

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
@export var stat_bonus: Dictionary       # base stat bonus values

func get_gems() -> Array[Gem]
func get_effective_stats_breakdown() -> Dictionary
func get_gems_stats_bonus() -> Dictionary
```

#### `Weapon` (`weapon.gd`)
```gdscript
class_name Weapon
extends Equipable

enum WeaponType { SWORD, AXE, BOW, STAFF, DAGGER }

@export var weapon_type: WeaponType
@export var base_attack_power: float = 10.0

func get_base_attack_power() -> float   # base_attack_power rounded to 1 decimal digit
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

#### `Consumable` & `Potion` (`consumable.gd`, `potion.gd`)
```gdscript
class_name Consumable
extends Item

enum ConsumableType { POTION, POISON }
@export var consumable_type: ConsumableType = ConsumableType.POTION

class_name Potion
extends Consumable

enum PotionType { HEALTH_POTION, MANA_POTION }
@export var potion_type: PotionType = PotionType.HEALTH_POTION
@export var heal_percentage: int = 10

func get_potion_effect() -> Dictionary
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

## HUD / UI Architecture (`in_game_ui.gd`)

`InGameUI` has `process_mode = Node.PROCESS_MODE_ALWAYS` — UI stays active even when the game tree is paused.

**Tabs in HUD Panel (`TabContainer`):**
| Tab | Scene Node | Contents |
| :--- | :--- | :--- |
| **Stats** | `StatsPanel` | `StatContainer` rows (one per stat in `STAT_NAMES_NO_FLT`), points label, Save/Cancel buttons |
| **Inventory** | `InventoryPanel` | 56 `InventorySlot` instances in a `GridContainer` |
| **Equipements** | `EquipementsPanel` | 9 wired `EquipementSlot` nodes |

**Potions Section (`$PotionsContainer`):**
Contains `health_potion_slot` and `mana_potion_slot` (`PotionSlot` instances).

**HUD toggle:** `PanelButton` (TextureButton) toggles `hud.visible`. Uses `openTexture` / `closeTexture` exports.

**Lootable items panel** (`$Control/LootableItemsTable`): Separate overlay. Contains a `GridContainer` with 20 `LootableItemSlot` instances. Pick All, Pick Selected, Cancel buttons.

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
| `_get_defense()` | `Player.gd`, `Enemy.gd` | `PlayerData.get_base_stats().get_def()` for player; `enemy_params.defense` for enemy |
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
10. **Class Stats are Duplicated:** `CharacterClass.get_class_stats()` returns `base_stats` — `PlayerData.initialize()` deep duplicates this instance (`stats.get_instance()`). Call `set_class_stats()` on the class resource to persist stat changes from equipment back to the class.
11. **StateMachine awaits owner.ready:** State nodes access `actor` and `state_machine` via `@onready`. This works because `StateMachine._ready()` itself `await owner.ready` before entering any states. Do not reference `actor` in state `_init()` or before the state machine is ready.
12. **Character debug Label:** `Character.gd` has an `@onready var label: Label = $Label` that updates each `_process` frame to display the current state name. This is a development aid — keep the `Label` node in all character scenes.
