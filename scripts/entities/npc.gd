## NPC
## Base class for non-combat world entities (NPCs) extending Character.
## Handles player interaction detection and dialogue parameters.
extends Character
class_name NPC

# ─── Exported Variables ──────────────────────────────────────────────────────
## The name of the NPC.
@export var npc_name: String = ""
## Dialogue text lines for the NPC.
@export_multiline var dialogue_text: Array[String] = []

# ─── Public Variables ────────────────────────────────────────────────────────
## Whether a player is currently in range to interact.
var is_player_in_range: bool = false
## Reference to the player body currently in range.
var player_in_range: Node2D = null

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var interaction_zone: Area2D = $InteractionZone

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()

# ─── Virtual Methods ─────────────────────────────────────────────────────────
## Virtual method called when interacting with the NPC.
func _interact() -> void: pass
func _wander() -> void: pass

func _idle() -> void:
	_play_idle_animation()

