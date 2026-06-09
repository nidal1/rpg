# CLAUDE.md — 2D Action RPG (Godot 4)

## Project Overview
A 2D Action RPG with a dark fantasy, Moroccan, and Arabic folklore theme. Medium scope (~3-4 hours gameplay) built natively in **Godot 4.x** using **GDScript**.

---

## Tech Stack & Commands
*   **Engine:** Godot 4.x (GDScript)
*   **Rendering:** 2D pixel art
*   **Physics:** `CharacterBody2D` for entities, `Area2D` for hitboxes/hurtboxes/projectiles
*   **Pathfinding:** `NavigationAgent2D` for intelligent enemy pathfinding and obstacle avoidance
*   **Running the Project:** Execute `godot --path .` from the command line, or open the project folder directly in the Godot 4 Editor.

---

## Architecture & Class Hierarchy

### Scene Hierarchy
```
Character.tscn              → Base CollisionShape2D only (pure parent scene)
  ├── Player.tscn           → Adds Camera2D, ComboAttackCD, Hurtbox, StateMachine, PickableDetection
  │     ├── Warrior.tscn    → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox (melee)
  │     ├── Archer.tscn     → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, SpawningPositions, Container (ranged)
  │     └── Mage.tscn       → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, SpawningPositions, Container, DetectionZone (spell)
  └── Enemy.tscn            → Adds NavigationAgent2D, DetectionZone, Hurtbox, StateMachine, WanderCD
        └── Goblin.tscn     → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox (melee enemy)
```

### Script Hierarchy
```
Character.gd (Character)     → Base entity: constants, health/mana stats, virtual hook functions, take_damage
  ├── Player.gd (Player)     → Handles user input, combo management, basic movement & idling, hit flashing
  │     ├── Warrior.gd       → Warrior class: handles melee hitbox collision triggers
  │     ├── Archer.gd        → Archer class: targets enemies, spawns and moves Arrow projectiles
  │     └── Mage.gd          → Mage class: targets enemies, spawns and moves WaterBullet projectiles
  └── Enemy.gd (Enemy)       → Base AI: targeting logic, NavigationAgent2D pathfinding, wander/chase movement, item dropping
        └── Goblin.gd        → Goblin class: handles specific animation transitions and melee hitbox detection
```

---

## Node-Based State Machine

The state machine separates entity states into decoupled, modular nodes under a parent `StateMachine`.

*   **StateMachine (`state_machine.gd`):** Dynamically registers child nodes inheriting from `State` into a registry dictionary (keys converted to lowercase) and handles `transition_to(state_name)` calls and `transitioned` signal emissions.
*   **State (`state.gd`):** Abstract base class containing standard lifecycle hooks: `enter()`, `exit()`, `handle_input()`, `update()`, and `physics_update()`. All states reference `actor` (their parent `Character`) and `state_machine`.

### Player States (`states/player/`)
| Class Name | Lowercase Name | Description |
| :--- | :--- | :--- |
| `PlayerIdleState` | `playeridlestate` | Calls `actor._idle()` to stop movement and play idle animation. Transitions to `playerrunstate` if input movement is received. |
| `PlayerRunState` | `playerrunstate` | Calls `actor._move()` to slide character and play run animations. Transitions to `playeridlestate` if movement input stops. |
| `PlayerAttackState`| `playerattackstate`| Stops movement and executes `actor._on_attack_pressed()`. Listens to `attack_ended` signal before returning to `playeridlestate`. |
| `PlayerDeadState`  | `playerdeadstate`  | Stops character movement and triggers custom virtual death logic via `actor._die()`. |

### Enemy States (`states/enemy/`)
| Class Name | Lowercase Name | Description |
| :--- | :--- | :--- |
| `EnemySpawnedState`| `enemyspawnedstate`| Loads custom `EnemyParams`, records initial spawn coordinates, connects to the global spawner's cleanup signals, and transitions to idle. |
| `EnemyIdleState`   | `enemyidlestate`   | Stops movement, travels to idle animation, and starts the wander cooldown. Transitions to chase or attack states reactively if player enters detection range. |
| `EnemyWanderState` | `enemywanderstate` | Picks a random cardinal direction (Left, Right, Up, Down) and navigates the enemy to that wander position. Returns to idle on arrival. |
| `EnemyPatrolState` | `enemypatrolstate` | Directs the enemy to navigate back to its original spawn position if it wandered too far or lost target aggro. |
| `EnemyRunState`    | `enemyrunstate`    | Basic running state that delegates movement to `actor._move()` based on target headings. |
| `EnemyChaseState`  | `enemychasestate`  | Updates pathfinding to track player position. Leashes the enemy: transitions back to patrol if player moves beyond `MAX_DISTANCE_TO_SPAWN_LOCATION` (700px). Transitions to attack when target is in range. |
| `EnemyAttackState` | `enemyattackstate` | Disables velocity and triggers cooldowned attack animation sequence. Transition evaluates target position after each attack completes. |
| `EnemyDeadState`   | `enemydeadstate`   | Disables movement, triggers death animation, and alerts spawning system to queue respawn. |

---

## Dynamic Gameplay Systems

### Lootable Items (Loot & Pickup)
*   **Naming Convention**: All dropped items and picked items follow the `Lootable Item` naming convention in both UI and logic.
*   **Mechanic**: Enemies drop `DropItem` (Area2D) physical objects into a `DropZone` when defeated. Each `DropItem` has a 30-second despawn timer (`despawn_time`) and auto-frees on timeout.
*   **Player Detection**: The player has a `PickableDetection` Area2D that identifies overlapping `DropItem` nodes. When an item enters the zone, `EventBus.lootable_item_added` is emitted.
*   **UI Integration**: The `InGameUI` catches the signal and populates `LootableItemSlot` panels in a dynamic GridContainer (up to 20 slots). Players can multi-select slots to pick them up, triggering `EventBus.selected_lootable_items_picked_up`.

### Inventory System (`inventory_slot.gd`, `in_game_ui.gd`)
A full 56-slot grid-based inventory displayed in the **Inventory Tab** of the HUD panel.
*   **`InventorySlot`:** Each slot holds one `Item` reference and displays its icon via a `TextureRect`. Right-clicking opens a `PopupMenu` with three actions:
    *   **Equip** — stub for future equip logic.
    *   **Use** — stub for future consumable logic.
    *   **Drop** — emits `EventBus.item_dropped_from_inventory(item)`, clears the slot, and spawns the item back into the world near the player.
*   **Item Drop-back Flow:** `GameManager._on_item_dropped_from_inventory()` instantiates a `drop.tscn`, locates the nearest `enemies_spawner`'s drop zone, and places the item at a randomized position near the player.
*   **Signals:** `items_added_to_inventory(slots: Array[Item])` and `items_removed_from_inventory(slots: Array[Item])` are broadcast after batch inventory changes.

### Projectiles (`arrow.gd`, `water_bullet.gd`)
Ranged characters shoot custom instances of projectiles (`Arrow`, `WaterBullet`) extending `Area2D`.
*   **Properties:** `speed`, `max_distance`, `direction`, `velocity`, `distance_traveled`.
*   **Lifecycle:** Projectiles are instantiated as **top-level** nodes (`set_as_top_level(true)`) to free their local transforms from the character node. They are added to a specific container (`arrows_container`, `bullets_container`) and automatically `queue_free()` if they exceed their target range or hit obstacles.
*   **Trigger Mechanism:** Archer and Mage bind a custom callback to animation events via signals (`_animation_editor_arrow_attack` and `_animation_editor_bullet_attack`). This allows the animator to fire arrows/spells at the exact frame the bow string is drawn or the staff is swung.

### Enemies Spawner (`enemies_spawner.gd`)
A modular system designed to auto-generate waves of enemies around specific level markers and manage physical drops.
*   **Parameters:** `spawn_point`, `enemies` (array of packed scenes), `spawn_circle_radius`, `respawn_cd`, `wander_cd_time`.
*   **Behavior:** Spawns random enemies at randomized positions within the circular radius. Handles automatic delayed respawning (`respawn_cd`) when an enemy's `on_died` signal fires.
*   **Drop Cleanup:** Listens to `selected_lootable_items_picked_up` to `queue_free()` the 2D sprites from the level's `DropZone` once they are picked up.

### Stat Allocation System (`player_data.gd`, `game_manager.gd`, `in_game_ui.gd`)
A transactional stat allocation system featuring a working copy and a backup copy:
*   **Working Copy (`__allocated_stats`):** The active dictionary containing the current stat points allocated. It is queried by `get_total()` to compute active combat stats dynamically in real-time.
*   **Backup Copy (`__temp_allocated_stats`):** Stores the last saved/committed state of the allocated stats.
*   **Lifecycle Operations:**
    *   `save_stats()`: Commits/duplicates the current `__allocated_stats` to the `__temp_allocated_stats` backup.
    *   `cancel_stats()`: Discards changes by reverting `__allocated_stats` back to the `__temp_allocated_stats` backup.

---

## Global Autoloads (Singletons)

The project leverages four major global Autoload nodes for decoupled state management and system communication:

*   **`EventBus` (`event_bus.gd`):** A centralized event broker routing global gameplay, UI updates, and transactional events. It manages signals for:
    *   *UI Synchronization:* `initialize_hero_stats_ui`, `update_hero_avatar_texture`, `update_hp_bar_value`, `update_mana_bar_value`.
    *   *Combat & Progression:* `enemy_died`, `enemy_spawned`, `xp_changed`, `level_up`.
    *   *Transactional Stats:* `stat_allocated`, `stat_deallocated`, `stats_updated`, `save_stats_points`, `cancel_stats_points`.
    *   *Lootable Items:* `lootable_item_added`, `lootable_item_removed`, `display_lootable_item_hover_info`, `hide_lootable_item_hover_info`, `selected_lootable_items_picked_up`.
    *   *Inventory:* `items_added_to_inventory`, `items_removed_from_inventory`, `item_dropped_from_inventory`.
*   **`PlayerData` (`player_data.gd`):** Holds player-specific data, levels, XP progression, inventory (`__current_inventory_items`), detected loot (`__lootable_items`), and stats allocations.
    *   *XP/Leveling:* Manages level values and computes target levels dynamically (e.g., target XP scaling).
    *   *Calculated Gameplay Stats:* Dynamically calculates attributes (e.g. `get_melee_atk()`, `get_ranged_atk()`, `get_magic_atk()`, `get_max_hp()`, `get_max_mp()`, `get_def()`, `get_resist()`, `get_crit_chance()`, `get_crit_damage()`) combining base character class attributes with user-allocated points.
    *   *Inventory Management:* Provides `add_inventory_item(item)` and `remove_inventory_item(item)` to manage the 56-slot flat `Array[Item]`.
*   **`GameManager` (`game_manager.gd`):** The orchestrator coordinating top-level game flow, player initialization, progression, and stat transactions:
    *   Registers the active player character and initializes `PlayerData` using the player class statistics.
    *   Listens to `EventBus.enemy_died` to award XP (from `enemy_params.xp_reward`) and trigger level-ups.
    *   Binds event bus transaction signals directly to `PlayerData` allocation routines and broadcasts updates via `EventBus.stats_updated`.
    *   Handles `item_dropped_from_inventory` to re-spawn `DropItem` instances into the nearest spawner's drop zone near the player.
*   **`SaveManager` (`save_manager.gd`):** Stub node reserved for handling persistence logic (saving/loading player progress).

---

## Project Folder Structure

```
res://
├── assets/                 → Audio resources, sprite sheets, tilesets, and UI themes
│   ├── sprites/player/     → Class assets (warrior, archer, mage)
│   ├── sprites/enemies/    → Monster assets (goblin, etc.)
│   ├── tilesets/
│   ├── ui/
│   └── audio/{sfx,music}/
├── scenes/                 → Game world zones and pre-configured nodes/hierarchies
│   ├── world/zones/
│   ├── entities/player/    → warrior.tscn, archer.tscn, mage.tscn, player.tscn, character.tscn, arrow.tscn, water_bullet.tscn
│   ├── entities/enemies/   → enemy.tscn, goblin.tscn, enemies_spawner.tscn
│   ├── entities/items/     → drop.tscn
│   ├── entities/npcs/      → (reserved)
│   ├── ui/                 → in_game_ui.tscn, lootable_item_slot.tscn, stat_container.tscn, inventory_slot.tscn
│   └── components/         → (reserved)
├── scripts/                → Gameplay logic scripts
│   ├── autoloads/          → Global stub services (event_bus.gd, game_manager.gd, player_data.gd, save_manager.gd)
│   ├── entities/           → Character, Player, Enemy, Archer, Mage, Warrior, Goblin, in_game_ui, lootable_item_slot, inventory_slot, stat_container, arrow, water_bullet, enemies_spawner
│   │   └── state_machine/  → state.gd & state_machine.gd controller scripts
│   │       └── states/     → player/ and enemy/ subdirectory state implementations
│   ├── resources/          → Shared core resources (attack_data.gd, drop.gd)
│   └── utils/
└── resources/              → Concrete .tres files representing game parameters
    ├── classes/            → warrior.tres, archer.tres, mage.tres, healer.tres (CharacterClass resources)
    ├── stats/              → warrior_stats.tres, archer_stats.tres, mage_stats.tres, priest.tres (CharacterStats resources)
    ├── attacks/            → combo attack configurations
    ├── enemies/            → goblin.tres (EnemyParams resources)
    ├── items/              → item.gd, weapon.gd, armor.gd, gem.gd + warrior/ and gems/ subdirs
    └── abilities/
```

---

## Physics Layers & Collision Settings

| Layer | Name | Purpose |
| :--- | :--- | :--- |
| **1** | world | Solid walls, terrain collisions, tilemaps |
| **2** | player | Main Player character physical boundaries |
| **3** | enemy | Main Enemy physical boundaries |
| **4** | player_hitbox | Player's damage-dealing areas |
| **5** | enemy_hitbox | Enemy's damage-dealing areas |
| **6** | player_hurtbox | Area where player accepts damage |
| **7** | enemy_hurtbox | Area where enemy accepts damage |

### Hitbox / Hurtbox Settings

| Node | Layer | Mask | Monitoring | Monitorable |
| :--- | :--- | :--- | :--- | :--- |
| **Player Body CollisionShape** | 2 | 1 | - | - |
| **Enemy Body CollisionShape** | 3 | 1 | - | - |
| **Player Hurtbox** | 6 | none | OFF | ON |
| **Enemy Hurtbox** | 7 | none | OFF | ON |
| **Warrior Hitbox (Melee)** | 4 | 7 | ON | OFF |
| **Enemy Hitbox (Melee)** | 5 | 6 | ON | OFF |

---

## Resource Schemas

### CharacterClass (`character_classes.gd`)
Used to configure initial statistics and combo trees for Warrior, Archer, Mage, and Healer:
```gdscript
class_name CharacterClass
extends Resource

@export var avatar_texture: Texture2D
@export var max_health: float = 100.0
@export var max_mana: float = 50.0
@export var speed: float = 300.0
@export var combo_chain: Array[AttackData] = []
@export var base_stats: CharacterStats
```

### CharacterStats (`character_stats.gd`)
Holds the base stat values for a character class. Loaded by `PlayerData.initialize()` to seed the allocation system:
```gdscript
class_name CharacterStats
extends Resource

@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var DEX: int = 0
@export var WIS: int = 0
@export var LUC: int = 0

# Equipment placeholders (populated by gear later)
@export var weapon_power: float = 0.0
@export var armor_value: float = 0.0
@export var armor_resist: float = 0.0
```

### AttackData (`attack_data.gd`)
Used to define individual beats in a combat combo string:
```gdscript
class_name AttackData
extends Resource

@export var anim_name: String = ""
@export var damage: float = 10.0
@export var combo_window: float = 1.2
```

### EnemyParams (`enemy_params.gd`)
Used to load parameters for monsters (e.g., Goblins):
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
@export var xp_reward: int = 25
@export var drop_list: Array[Item] = []
```

### Item System (`resources/items/`)
A class hierarchy for all in-game items. All types extend the base `Item` resource.

#### Item (base — `item.gd`)
```gdscript
class_name Item
extends Resource

enum ItemType { WEAPON, ARMOR, GEM, CONSUMABLE }
enum Rarity   { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType
@export var rarity: Rarity = Rarity.COMMON
```

#### Weapon (`weapon.gd`)
```gdscript
class_name Weapon
extends Item

enum WeaponType { SWORD, AXE, BOW, STAFF, DAGGER }

@export var weapon_type: WeaponType
@export var base_attack_power: float = 10.0
@export var level: int = 1
@export var gems: Array[Gem] = []  # max 2-3 slots

func get_total_attack_power() -> float  # base + gem ATK bonuses
```

#### Armor (`armor.gd`)
```gdscript
class_name Armor
extends Item

enum ArmorType { HELMET, CHEST, BOOTS, GLOVES, SHIELD }

@export var armor_type: ArmorType
@export var base_defense: float = 5.0
@export var base_resist: float = 0.0
@export var level: int = 1
@export var gems: Array[Gem] = []

func get_total_defense() -> float  # base_defense + gem DEF bonuses
```

#### Gem (`gem.gd`)
Socketed into `Weapon.gems` or `Armor.gems`. Each gem has per-level bonus arrays (levels 1–3):
```gdscript
class_name Gem
extends Item

enum GemType { RUBY, SAPPHIRE, EMERALD, TOPAZ, AMETHYST, DIAMOND }

@export var gem_type: GemType
@export var gem_level: int = 1  # 1-3

@export var atk_bonus: Array[float] = []
@export var def_bonus: Array[float] = []
@export var hp_bonus:  Array[float] = []
@export var mp_bonus:  Array[float] = []
@export var crit_bonus: Array[float] = []

# Accessors index by (gem_level - 1)
func get_atk_bonus() -> float
func get_def_bonus() -> float
func get_hp_bonus()  -> float
func get_mp_bonus()  -> float
func get_crit_bonus() -> float
```

---

## Coding Standards & Virtual Functions

The project rigorously enforces the official GDScript structure across all `.gd` scripts, utilizing `##` for documentation and preserving order: 
`extends` -> `class_name` -> `signals` -> `constants` -> `exports` -> `public/onready vars` -> `built-in overrides` -> `public methods` -> `virtual methods` -> `private methods` -> `signal handlers`.

All entities utilize a **Virtual Functions Override Pattern** to separate core state machine code from concrete class logic:

| Function | Overriding Context | Purpose |
| :--- | :--- | :--- |
| `_move()` | `Player.gd`, `Enemy.gd` | Implements physics movement (`move_and_slide`) & movement anims |
| `_idle()` | `Player.gd`, `Enemy.gd` | Implements zero velocity & idle anim travel |
| `_attack()` | `Player.gd`, `Enemy.gd` | Initiates basic combos or starts attack timers |
| `_die()` | `Player.gd`, `Enemy.gd` | Triggers death queues & removes entity |
| `_on_damage_received()`| `Player.gd`, `Enemy.gd` | Controls hit flash, UI logs, and transitions to DeadState |
| `_play_movement_animation()`| `Player.gd`, `Goblin.gd` | Feeds blend positions to the active AnimationTree |
| `_play_idle_animation()`| `Player.gd`, `Goblin.gd` | Feeds blend positions to the active AnimationTree |
| `_play_attack_animation()`| `Player.gd`, `Goblin.gd` | Custom blend positions specifically for weapon attacks |

### Essential Developer Rules

1.  **Await Safely:** Always check `is_instance_valid(actor)` after any `await` or `create_timer` statement inside a state script (e.g. `await get_tree().create_timer(cooldown).timeout`). If the actor was killed during the delay, referencing it will crash the game.
2.  **Top-Level Projectiles:** Projectiles must be detached from their shooter's spatial transform hierarchy using `set_as_top_level(true)` to ensure realistic flight lines that are unaffected by shooter movement.
3.  **State Machine Transitions:** Transition calls use lowercase strings matched dynamically in `state_machine.gd` (e.g., `transitioned.emit("enemychasestate")`). Avoid using enums for state machine transitions.
4.  **Hitbox Keying:** Enable and disable `CollisionShape2D` nodes on combat Hitboxes directly inside Godot's Animation Player timeline tracks. Do not enable hitboxes manually in persistent update scripts.
5.  **Scene Inheritance:** Every subclass scene (Warrior, Archer, Mage, Goblin) must be created as an **Inherited Scene** from their respective parent templates (`Player.tscn` or `Enemy.tscn`) to preserve node configurations.
6.  **Item Drop-back:** When dropping items from inventory, use `GameManager.drop_item(item)` which locates the nearest `enemies_spawner` group node's drop zone. Do not add drop scenes directly to the scene tree from UI scripts.
