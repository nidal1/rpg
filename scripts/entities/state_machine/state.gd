## State
## Base class for all states in the StateMachine. Provides virtual methods
## for standard state behavior (enter, exit, update, input).
extends Node
class_name State

# ─── Signals ─────────────────────────────────────────────────────────────────
## Emitted when this state requests a transition to another state.
signal transitioned(state_name: String)

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var actor: Character = owner as Character
@onready var state_machine: StateMachine = get_parent() as StateMachine

# ─── Virtual Methods ─────────────────────────────────────────────────────────
## Called when the state machine enters this state.
func enter() -> void:
	pass

## Called when the state machine exits this state.
func exit() -> void:
	pass

## Called to handle unhandled input events while this state is active.
func handle_input(_event: InputEvent) -> void:
	pass

## Called during the process loop while this state is active.
func update(_delta: float) -> void:
	pass

## Called during the physics process loop while this state is active.
func physics_update(_delta: float) -> void:
	pass
