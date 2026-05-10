# state.gd
extends Node
class_name State

signal transitioned(state_name: String)

@onready var actor: Character = owner as Character
@onready var state_machine: StateMachine = get_parent() as StateMachine

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
