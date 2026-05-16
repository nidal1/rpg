# CLAUDE.md — 2D Action RPG (Godot 4)

## Project Overview
2D Action RPG with dark fantasy + Moroccan/Arabic folklore theme. Medium scope (~3-4 hours gameplay). Built with Godot 4.

## Tech Stack
- **Engine:** Godot 4.x (GDScript)
- **Rendering:** 2D, pixel art
- **Physics:** CharacterBody2D

---

## Architecture

### Scene Hierarchy
```
Character.tscn          → CollisionShape2D only (pure base)
  └── Player.tscn       → + Camera2D, ComboAttackCD, Hurtbox
        └── Warrior.tscn → + AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox
        └── Archer.tscn  → + AnimatedSprite2D, AnimationPlayer, AnimationTree (no Hitbox)
        └── Mage.tscn    → + AnimatedSprite2D, AnimationPlayer, AnimationTree (no Hitbox)
  └── Enemy.tscn        → + NavigationAgent2D, DetectionZone, Hurtbox
        └── Goblin.tscn  → + AnimatedSprite2D, AnimationPlayer, AnimationTree, Hitbox
```

### Script Hierarchy
```
Character.gd    → base class: signals, take_damage, virtual functions
  └── Player.gd → input, combo system, _physics_process
  └── Enemy.gd  → AI logic, NavigationAgent2D, wander timer
        └── Goblin.gd → animation overrides, specific behavior

### State Machine Architecture (Node-based)
- **StateMachine**: Node that manages child State nodes. Transitions via `transitioned(state_name)` signal.
- **State**: base class for all states. Contains `enter()`, `exit()`, `handle_input()`, `update()`, `physics_update()`.
- **Naming Convention**: `playeridle`, `playerrun`, `enemyattack`, etc. (lower-case strings used in scene tree).

### Folder Structure
```
res://
├── assets/
├── scenes/
├── scripts/
│   ├── autoloads/
│   ├── entities/
│   │   └── state_machine/
│   │       ├── state_machine.gd, state.gd
│   │       └── states/
│   │           ├── player/ (player_idle_state.gd, ...)
│   │           └── enemy/  (enemy_idle_state.gd, ...)
│   ├── resources/
│   └── utils/
└── resources/
```

### Autoloads
| Name | Path | Purpose |
|------|------|---------|
| GameManager | scripts/autoloads/game_manager.gd | Game state, pause |
| EventBus | scripts/autoloads/event_bus.gd | Global signals |
| SaveManager | scripts/autoloads/save_manager.gd | Save/load |

---

## Folder Structure
```
res://
├── assets/
│   ├── sprites/player/{warrior,archer,mage}/
│   ├── sprites/enemies/
│   ├── tilesets/
│   ├── ui/
│   └── audio/{sfx,music}/
├── scenes/
│   ├── world/zones/
│   ├── entities/player/    → character.tscn, player.tscn, warrior.tscn ...
│   ├── entities/enemies/   → enemy.tscn, goblin.tscn ...
│   ├── ui/
│   └── components/
├── scripts/
│   ├── autoloads/
│   ├── resources/          → attack_data.gd, character_classes.gd ...
│   └── utils/
└── resources/
    ├── classes/            → warrior.tres, archer.tres ...
    ├── attacks/            → warrior_attack1.tres ...
    └── abilities/
```

---

## Physics Layers
| Layer | Name |
|-------|------|
| 1 | world |
| 2 | player |
| 3 | enemy |
| 4 | player_hitbox |
| 5 | enemy_hitbox |
| 6 | player_hurtbox |
| 7 | enemy_hurtbox |

### Hitbox / Hurtbox Settings
| Node | Layer | Mask | Monitoring | Monitorable |
|------|-------|------|------------|-------------|
| Player CollisionShape | 2 | 1 | - | - |
| Enemy CollisionShape | 3 | 1 | - | - |
| Player Hurtbox | 6 | none | OFF | ON |
| Enemy Hurtbox | 7 | none | OFF | ON |
| Warrior Hitbox | 4 | 7 | ON | OFF |
| Enemy Hitbox | 5 | 6 | ON | OFF |

---

## Node Groups
```
Character.tscn  → "character"
Player.tscn     → "character", "player"
Warrior.tscn    → "character", "player", "warrior"
Enemy.tscn      → "character", "enemy"
Goblin.tscn     → "character", "enemy", "goblin"
```

---

## Input Map
| Action | Keys |
|--------|------|
| move_left | A / Arrow Left |
| move_right | D / Arrow Right |
| move_up | W / Arrow Up |
| move_down | S / Arrow Down |
| attack | Mouse Left |
| interact | E / F |
| pause | Escape |
| open_inventory | I / Tab |

---

## Resources

### AttackData (attack_data.gd)
```gdscript
@export var anim_name: String = ""
@export var damage: float = 10.0
@export var combo_window: float = 1.2
```

### CharacterClass (character_classes.gd)
```gdscript
@export var class_name_id: String = ""
@export var max_health: float = 100.0
@export var speed: float = 300.0
@export var combo_chain: Array[AttackData] = []
@export var base_stats: CharacterStats
@export var abilities: Array[Ability] = []
```

---

## Combo System
- `combo_chain: Array[AttackData]` — ordered list of attacks per class
- `combo_index` — current attack (-1 = not attacking)
- `combo_queued` — player pressed attack during current attack window
- `ComboAttackCD` Timer — combo window duration per attack (`attack.combo_window`)
- Flow: click → `_start_combo` → `_execute_attack` → timer → next or `_end_combo`

### AnimationTree Structure (Warrior)
```
Root StateMachine
├── idle    (BlendSpace1D — left/right)
├── run     (BlendSpace1D — left/right)
└── basic_attack (BlendSpace / StateMachine)
    └── BasicAttackStateMachine
        ├── Start → attack1 → attack2 → End
        └── Start → attack1 → End (fallback)
```

### Transition Setup
```
attack1 → attack2 : immediate, advanced enabled  (travel from code)
attack1 → End     : at the end, advanced enabled  (fallback)
attack2 → End     : at the end, auto
```

---

## Virtual Functions Pattern
All animation and behavior-specific logic goes in subclasses via overrides:

| Function | Where overridden |
|----------|-----------------|
| `_on_state_changed(state)` | Warrior.gd, Goblin.gd |
| `_play_attack_animation(attack)` | Warrior.gd |
| `_move()` | Warrior.gd, Enemy.gd |
| `_idle()` | Warrior.gd |
| `_on_damage_received()` | Warrior.gd, Enemy.gd |
| `_die()` | Enemy.gd |
| `_on_movement_updated()` | Goblin.gd |
| `_get_attack_damage()` | Enemy.gd |

---

## Key Rules
- **State Machine**: States are decoupled into `player/` and `enemy/` subdirectories.
- **Enemy Logic**: Transitions between states (like `Idle` and `Attack`) are handled reactively in `physics_update`.
- **Transitions**: Use lower-case strings in `transitioned.emit("statename")` (e.g., `enemyidlestate`, `playerattackstate`).
- **Cooldowns**: Handled by `await` within the attack functions.
- Always check `is_instance_valid(actor)` after any `await` inside a State.
- Hitbox CollisionShape enable/disable per animation frame.
- Each subclass scene must inherit from correct parent scene.
