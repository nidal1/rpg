## Character
## Base class for all characters in the game, including the player, enemies, and NPCs.
## Provides core movement, entity identity, and state management functionality.
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

# ─── Exported Variables ──────────────────────────────────────────────────────
## Optional entity name identifier.
@export var entity_name: String = ""

# ─── Public Variables ────────────────────────────────────────────────────────
## The current facing direction vector.
var direction: Vector2 = Vector2.ZERO
## The last faced direction (1.0 for right, -1.0 for left).
var last_facing_dir: float = 1.0
## Deprecated state variable.
var current_state: DeprecatedState = DeprecatedState.IDLE
## Base movement speed.
var speed: float = 0.0

## Reference to the character's animation tree.
var animation_tree: AnimationTree = null
## Playback for the main state machine.
var animation_playback: AnimationNodeStateMachinePlayback = null

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var label: Label = $Label
@onready var state_machine: StateMachine = $StateMachine

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	_update_label_state()

func _process(_delta: float) -> void:
	# Update label periodically to reflect state changes
	_update_label_state()

# ─── Virtual Methods ─────────────────────────────────────────────────────────
## Virtual method for movement logic.
func _move() -> void: pass
## Virtual method for idle logic.
func _idle() -> void: pass
## Virtual method for playing movement animations.
func _play_movement_animation() -> void: pass
## Virtual method for playing idle animations.
func _play_idle_animation() -> void: pass
## Virtual method called when the state changes (Deprecated).
func _on_state_changed(_new_state: DeprecatedState) -> void: pass

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

