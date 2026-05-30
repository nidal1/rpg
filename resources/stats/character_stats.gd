extends Resource
class_name CharacterStats

# ─── Base Stats ──────────────────────────────────────
@export var STR: int = 0
@export var REC: int = 0
@export var INT: int = 0
@export var DEX: int = 0
@export var WIS: int = 0
@export var LUC: int = 0

# ─── Weapon Power (set by equipment later) ───────────
@export var weapon_power: float = 0.0
@export var armor_value: float = 0.0
@export var armor_resist: float = 0.0
