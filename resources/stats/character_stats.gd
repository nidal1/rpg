extends Resource
class_name CharacterStats

# ─── Base Stats ──────────────────────────────────────
@export var max_health: float = 0.0
@export var max_mana: float = 0.0

@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var DEX: int = 0
@export var WIS: int = 0
@export var LUC: int = 0

# ─── Weapon Power (set by equipment later) ───────────
var weapon_power: float = 0.0
var armor_defense: float = 0.0
var armor_resist: float = 0.0
