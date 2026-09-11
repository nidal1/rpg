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
@onready var interaction_area: Area2D = $InteractionArea

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	if interaction_area:
		if not interaction_area.body_entered.is_connected(_on_interaction_area_body_entered):
			interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		if not interaction_area.body_exited.is_connected(_on_interaction_area_body_exited):
			interaction_area.body_exited.connect(_on_interaction_area_body_exited)

# ─── Virtual Methods ─────────────────────────────────────────────────────────
## Virtual method called when interacting with the NPC.
func _interact() -> void:
	pass

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = true
		player_in_range = body

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
		player_in_range = null
