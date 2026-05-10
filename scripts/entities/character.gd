extends CharacterBody2D
class_name Character

@onready var label: Label = $Label
@onready var state_machine: StateMachine = $StateMachine

var animation_tree: AnimationTree = null
var animation_playback: AnimationNodeStateMachinePlayback = null
var animation_BA_playback: AnimationNodeStateMachinePlayback = null

# Deprecated: Enum state is being replaced by Node-based StateMachine
enum DeprecatedState {IDLE, RUN, ATTACKING, PATROL, CHASE, FLEE, DEAD}

const ANIM_IDLE = "idle"
const ANIM_RUN = "run"

var direction: Vector2 = Vector2.ZERO
var last_facing_dir: float = 1.0
var current_state: DeprecatedState = DeprecatedState.IDLE # Deprecated
var max_health: float = 100.0

func _ready() -> void:
	_update_label_state()

# ─── Virtual functions ────────────────────────────────────────────
func _move() -> void: pass
func _idle() -> void: pass
func _attack() -> void: pass
func _die() -> void: pass
func _on_damage_received() -> void: pass
func _play_movement_animation() -> void: pass
func _play_idle_animation() -> void: pass
func _on_state_changed(new_state: DeprecatedState) -> void: pass
func _get_attack_damage() -> float: return 0.0

# ─── State (Deprecated) ────────────────────────────────────────
func _set_state(new_state: DeprecatedState) -> void:
	if current_state == new_state: return
	current_state = new_state
	_update_label_state()
	_on_state_changed(new_state)

# ─── Combat ──────────────────────────────────────────────
func take_damage(amount: float) -> void:
	max_health -= amount
	_on_damage_received()

func _update_label_state() -> void:
	if state_machine and state_machine.current_state:
		label.text = state_machine.current_state.name
	else:
		label.text = DeprecatedState.keys()[current_state]

# ─── Input ───────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		state_machine.transition_to("attackstate")

func _process(_delta: float) -> void:
	# Update label periodically to reflect state changes
	_update_label_state()
