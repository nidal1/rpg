extends Resource
class_name EnemyParams

@export var enemy_name: String = "Enemy"
@export var enemy_level: int = 1
@export var enemy_rank: ProgressionManager.EnemyRank = ProgressionManager.EnemyRank.NORMAL
@export var enemy_avatar: Texture2D
@export var max_health: float = 100.0
@export var speed: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 70.0
@export var base_recovery_delay: float = 1.0
@export var base_attack_anim_duration: float = 1.0
@export var defense: float = 0.0
@export var resistance: float = 0.0
@export var custom_db_item_objects: Array[DataItem] = []
