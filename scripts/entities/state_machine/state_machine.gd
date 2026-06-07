## StateMachine
## A node that manages a collection of State nodes and handles transitions
## between them. Delegates input and physics updates to the current state.
extends Node
class_name StateMachine

# ─── Exported Variables ──────────────────────────────────────────────────────
## The initial state the machine should enter when ready.
@export var initial_state: State

# ─── Public Variables ────────────────────────────────────────────────────────
## The currently active state.
var current_state: State
## Dictionary mapping state names (lowercase strings) to their State nodes.
var states: Dictionary = {}

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	# Wait for owner (Character) to be ready
	await owner.ready
	
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(_on_state_transitioned)
	
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

# ─── Public Methods ──────────────────────────────────────────────────────────
## Transitions the state machine to the specified state.
func transition_to(state_name: String) -> void:
	_on_state_transitioned(state_name)

# ─── Signal Handlers ─────────────────────────────────────────────────────────
## Internal handler for state transition signals.
func _on_state_transitioned(state_name: String) -> void:
	var new_state = states.get(state_name.to_lower())
	if not new_state:
		printerr("StateMachine: State '", state_name, "' not found!")
		return
	
	if current_state:
		if current_state == new_state: return
		current_state.exit()
	
	current_state = new_state
	current_state.enter()
