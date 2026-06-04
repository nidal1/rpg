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
  ├── Player.tscn           → Adds Camera2D, ComboAttackCD, Hurtbox, StateMachine
  │     ├── Warrior.tscn    → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox (melee)
  │     ├── Archer.tscn     → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, SpawningPositions, Container (ranged)
  │     └── Mage.tscn       → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, SpawningPositions, Container, DetectionZone (spell)
  └── Enemy.tscn            → Adds NavigationAgent2D, DetectionZone, Hurtbox, StateMachine, WanderCD
        └── Goblin.tscn     → Adds AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox (melee enemy)
```

### Script Hierarchy
```
Character.gd (Character)     → Base entity: signals, take_damage, virtual hook functions
  ├── Player.gd (Player)     → Handles user input, combo management, basic movement & idling, hit flashing
  │     ├── Warrior.gd       → Warrior class: handles melee hitbox collision triggers
  │     ├── Archer.gd        → Archer class: targets enemies, spawns and moves Arrow projectiles
  │     └── Mage.gd          → Mage class: targets enemies, spawns and moves WaterBullet projectiles
  └── Enemy.gd (Enemy)       → Base AI: targeting logic, NavigationAgent2D pathfinding, wander/chase movement
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

### Projectiles (`arrow.gd`, `water_bullet.gd`)
Ranged characters shoot custom instances of projectiles (`Arrow`, `WaterBullet`) extending `Area2D`.
*   **Properties:** `speed`, `max_distance`, `direction`, `velocity`, `distance_traveled`.
*   **Lifecycle:** Projectiles are instantiated as **top-level** nodes (`set_as_top_level(true)`) to free their local transforms from the character node. They are added to a specific container (`arrows_container`, `bullets_container`) and automatically `queue_free()` if they exceed their target range or hit obstacles.
*   **Trigger Mechanism:** Archer and Mage bind a custom callback to animation events via signals (`_animation_editor_arrow_attack` and `_animation_editor_bullet_attack`). This allows the animator to fire arrows/spells at the exact frame the bow string is drawn or the staff is swung.

### Enemies Spawner (`enemies_spawner.gd`)
A modular system designed to auto-generate waves of enemies around specific level markers.
*   **Parameters:** `spawn_point`, `enemies` (array of packed scenes), `spawn_circle_radius`, `respawn_cd`, `wander_cd_time`.
*   **Behavior:** Spawns random enemies at randomized positions within the circular radius. Handles automatic delayed respawning (`respawn_cd`) when an enemy's `on_died` signal fires.

### Stat Allocation System (`player_data.gd`, `game_manager.gd`, `in_game_ui.gd`)
A transactional stat allocation system featuring a working copy and a backup copy:
*   **Working Copy (`__allocated_stats`):** The active dictionary containing the current stat points allocated. It is queried by `get_total()` to compute active combat stats dynamically in real-time.
*   **Backup Copy (`__temp_allocated_stats`):** Stores the last saved/committed state of the allocated stats.
*   **Lifecycle Operations:**
    *   `save_stats()`: Commits/duplicates the current `__allocated_stats` to the `__temp_allocated_stats` backup.
    *   `cancel_stats()`: Discards changes by reverting `__allocated_stats` back to the `__temp_allocated_stats` backup.
*   **UI Safety:** The UI (`in_game_ui.gd`) clears previous children using `queue_free()` before re-instantiating `StatContainer` nodes to prevent duplicate layout entries on initialization/re-open.

### Global Autoloads (Singletons)

The project leverages four major global Autoload nodes for decoupled state management and system communication:

*   **`EventBus` (`event_bus.gd`):** A centralized event broker routing global gameplay, UI updates, and transactional events. It manages signals for:
    *   *UI Synchronization:* `initialize_hero_stats_ui`, `update_hero_avatar_texture`, `update_hp_bar_value`, `update_mana_bar_value`.
    *   *Combat & Progression:* `enemy_died`, `xp_changed`, `level_up`.
    *   *Transactional Stats:* `stat_allocated`, `stat_deallocated`, `stats_updated`, `save_stats_points`, `cancel_stats_points`.
*   **`PlayerData` (`player_data.gd`):** Holds player-specific data, levels, XP progression, and stats allocations.
    *   *XP/Leveling:* Manages level values and computes target levels dynamically (e.g., target XP scaling).
    *   *Transactional Allocations:* Features a working copy (`__allocated_stats`) and a backup copy (`__temp_allocated_stats`) to allow reverting state changes when editing stats in the UI.
    *   *Calculated Gameplay Stats:* Dynamically calculates attributes (e.g. `get_melee_atk()`, `get_ranged_atk()`, `get_magic_atk()`, `get_max_hp()`, `get_max_mp()`, `get_def()`, `get_resist()`, `get_crit_chance()`, `get_crit_damage()`) combining base character class attributes with user-allocated points.
*   **`GameManager` (`game_manager.gd`):** The orchestrator coordinating top-level game flow, player initialization, progression, and stat transactions:
    *   Registers the active player character and initializes `PlayerData` using the player class statistics.
    *   Listens to `EventBus.enemy_died` to award XP and trigger level-ups.
    *   Binds event bus transaction signals directly to `PlayerData` allocation routines (e.g., `allocate_point`, `deallocate_point`, `save_stats_points`, `cancel_stats_points`) and broadcasts updates via `EventBus.stats_updated`.
*   **`SaveManager` (`save_manager.gd`):** Currently a lightweight stub node reserved for future persistence systems.




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
│   ├── entities/player/    → warrior.tscn, archer.tscn, mage.tscn, player.tscn, character.tscn
│   ├── entities/enemies/   → enemy.tscn, goblin.tscn
│   ├── ui/
│   └── components/
├── scripts/                → Gameplay logic scripts
│   ├── autoloads/          → Global stub services (GameManager, EventBus, SaveManager)
│   ├── entities/           → Character, Player, Enemy class scripts and spawner scripts
│   │   └── state_machine/  → base state.gd & state_machine.gd controller scripts
│   │       └── states/     → player/ and enemy/ subdirectory state implementations
│   ├── resources/          → Shared core resources (attack_data.gd)
│   └── utils/
└── resources/              → Concrete .tres files representing game parameters
    ├── classes/            → warrior.tres, archer.tres, mage.tres (CharacterClass resources)
    ├── attacks/            → combo attack configurations
    ├── enemies/            → goblin_params.tres, etc. (EnemyParams resources)
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

## Node Groups
Assign nodes to these groups to keep logic simple and prevent dynamic casting checks:
*   `Character.tscn` → `"character"`
*   `Player.tscn` (and subclasses) → `"character"`, `"player"`, plus specific classes like `"warrior"`, `"archer"`, `"mage"`
*   `Enemy.tscn` (and subclasses) → `"character"`, `"enemy"`, plus specific breeds like `"goblin"`
*   `EnemiesSpawner` → `"enemies_spawner"`

---

## Input Map Action Bindings

| Action | Keys |
| :--- | :--- |
| `move_left` | A / Arrow Left |
| `move_right` | D / Arrow Right |
| `move_up` | W / Arrow Up |
| `move_down` | S / Arrow Down |
| `attack` | Mouse Left |
| `interact` | E / F |
| `pause` | Escape |
| `open_inventory`| I / Tab |

---

## Resource Schemas

### CharacterClass (`character_classes.gd`)
Used to configure initial statistics and combo trees for Warrior, Archer, and Mage:
```gdscript
class_name CharacterClass
extends Resource

@export var max_health: float = 100.0
@export var max_mana: float = 50.0
@export var speed: float = 300.0
@export var combo_chain: Array[AttackData] = []
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
@export var max_health: float = 100.0
@export var speed: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 70.0
@export var attack_cooldown: float = 2.2
```

---

## Combo System & Animations

*   **Logic:** Combos are handled via `combo_chain: Array[AttackData]` and driven by a `ComboAttackCD` Timer.
*   **Combo Queueing:** Pressing attack during the active window triggers `combo_queued = true`. When the timer expires, the queue proceeds to the next attack in the array or resets to index `-1` (idle).
*   **Warrior AnimationTree Structure:**
    ```
    Root StateMachine
    ├── idle              (BlendSpace1D — left/right)
    ├── run               (BlendSpace1D — left/right)
    └── basic_attack      (Sub-StateMachine)
        └── BasicAttackStateMachine
            ├── Start → attack1 → attack2 → End
            └── Start → attack1 → End (fallback)
    ```

---

## Coding Standards & Virtual Functions

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
