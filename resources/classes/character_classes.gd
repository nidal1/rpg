class_name CharacterClass
extends Resource

@export var class_name_id: String = ""        # "warrior", "archer", etc.
@export var max_health: float = 100.0
@export var max_mana: float = 50.0
@export var speed: float = 300.0
@export var combo_chain: Array[AttackData] = []
