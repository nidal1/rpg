class_name CharacterClass
extends Resource

enum PlayerType {WARRIOR, ARCHER, MAGE, PRIEST, ALL}

@export var player_type: PlayerType = PlayerType.WARRIOR
@export var avatar_texture: Texture2D
@export var speed: float = 300.0
@export var combo_chain: Array[AttackData] = []
@export var base_stats: CharacterStats

func set_class_stats(stats: CharacterStats) -> void:
	base_stats = stats.duplicate(true)

func get_class_stats() -> CharacterStats:
	return base_stats.duplicate(true)

func get_class_stats_instance() -> CharacterStats:
	return base_stats.get_instance().duplicate(true)
