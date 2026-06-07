## AttackData
## Resource containing data about a specific attack animation and its properties.
extends Resource
class_name AttackData

# ─── Exported Variables ──────────────────────────────────────────────────────
## The name of the animation to play for this attack.
@export var anim_name: String = ""
## The damage dealt by this attack.
@export var damage: float = 10.0
## The time window (in seconds) allowed to chain the next combo attack.
@export var combo_window: float = 1.2
