## Character
## Base class for all characters in the game, including the player and enemies.
## Provides core movement, health, and state management functionality.
extends CharacterBody2D
class_name Character

# ─── Constants ───────────────────────────────────────────────────────────────
## Name of the idle animation.
const ANIM_IDLE = "idle"
## Name of the run animation.
const ANIM_RUN = "run"

# ─── Enums (Deprecated) ──────────────────────────────────────────────────────
# Deprecated: Enum state is being replaced by Node-based StateMachine
enum DeprecatedState {IDLE, RUN, ATTACKING, PATROL, CHASE, FLEE, DEAD}

# ─── Public Variables ────────────────────────────────────────────────────────
## The current facing direction vector.
var direction: Vector2 = Vector2.ZERO
## The last faced direction (1.0 for right, -1.0 for left).
var last_facing_dir: float = 1.0
## Deprecated state variable.
var current_state: DeprecatedState = DeprecatedState.IDLE
## Base movement speed.
var speed: float = 0.0

# TODO: move stats to Player class instead of Character class
## Maximum mana points.
var max_mana: float = 0.0
## Maximum health points.
var max_health: float = 0.0
## Current health points.
var current_health: float = 0.0
## Current mana points.
var current_mana: float = 0.0

## Reference to the character's animation tree.
var animation_tree: AnimationTree = null
## Playback for the main state machine.
var animation_playback: AnimationNodeStateMachinePlayback = null
## Playback for basic attacks.
var animation_BA_playback: AnimationNodeStateMachinePlayback = null

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var label: Label = $Label
@onready var state_machine: StateMachine = $StateMachine

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	_update_label_state()

func _process(_delta: float) -> void:
	# Update label periodically to reflect state changes
	_update_label_state()

# ─── Public Methods ──────────────────────────────────────────────────────────
## Applies damage to the character.
func take_damage(amount: float) -> void:
	var reduced_damage = max(1.0, amount - _get_defense())
	if self is Player:
		print("reduced damage: ", reduced_damage)
	current_health -= reduced_damage
	_on_damage_received()

# ─── Virtual Methods ─────────────────────────────────────────────────────────
## Virtual method for movement logic.
func _move() -> void: pass
## Virtual method for idle logic.
func _idle() -> void: pass
## Virtual method for attack logic.
func _attack() -> void: pass
## Virtual method for death logic.
func _die() -> void: pass
## Virtual method called when damage is received.
func _on_damage_received() -> void: pass
## Virtual method for playing movement animations.
func _play_movement_animation() -> void: pass
## Virtual method for playing idle animations.
func _play_idle_animation() -> void: pass
## Virtual method called when the state changes (Deprecated).
func _on_state_changed(new_state: DeprecatedState) -> void: pass
## Virtual method that returns the current attack damage.
func _get_attack_damage() -> float: return 0.0
## Virtual method that returns the current defense.
func _get_defense() -> float: return 0.0
# ─── Private Methods ─────────────────────────────────────────────────────────
## Updates the debug label with the current state name.
func _update_label_state() -> void:
	if state_machine and state_machine.current_state:
		label.text = state_machine.current_state.name
	else:
		label.text = DeprecatedState.keys()[current_state]

## Deprecated method to set the character's state.
func _set_state(new_state: DeprecatedState) -> void:
	if current_state == new_state: return
	current_state = new_state
	_update_label_state()
	_on_state_changed(new_state)
