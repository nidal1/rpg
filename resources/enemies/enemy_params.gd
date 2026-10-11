extends Resource
class_name EnemyParams

@export var enemy_name: String = "Enemy": set = set_enemy_name, get = get_enemy_name
@export var enemy_level: int = 1: set = set_enemy_level, get = get_enemy_level
@export var enemy_rank: ProgressionManager.EnemyRank = ProgressionManager.EnemyRank.NORMAL: set = set_enemy_rank, get = get_enemy_rank
@export var enemy_avatar: Texture2D: set = set_enemy_avatar, get = get_enemy_avatar
@export var max_health: float = 100.0: set = set_max_health, get = get_max_health
@export var speed: float = 100.0: set = set_speed, get = get_speed
@export var attack_damage: float = 10.0: set = set_attack_damage, get = get_attack_damage
@export var attack_range: float = 70.0: set = set_attack_range, get = get_attack_range
@export var base_recovery_delay: float = 1.0: set = set_base_recovery_delay, get = get_base_recovery_delay
@export var base_attack_anim_duration: float = 1.0: set = set_base_attack_anim_duration, get = get_base_attack_anim_duration
@export var defense: float = 0.0: set = set_defense, get = get_defense
@export var resistance: float = 0.0: set = set_resistance, get = get_resistance
@export var custom_db_item_objects: Array[DataItem] = []: set = set_custom_db_item_objects, get = get_custom_db_item_objects


# --- Getters and Setters ---

func set_enemy_name(value: String) -> void:
	enemy_name = value

func get_enemy_name() -> String:
	return enemy_name


func set_enemy_level(value: int) -> void:
	enemy_level = max(1, value) # Example: ensure level is at least 1

func get_enemy_level() -> int:
	return enemy_level


func set_enemy_rank(value: ProgressionManager.EnemyRank) -> void:
	enemy_rank = value

func get_enemy_rank() -> ProgressionManager.EnemyRank:
	return enemy_rank


func set_enemy_avatar(value: Texture2D) -> void:
	enemy_avatar = value

func get_enemy_avatar() -> Texture2D:
	return enemy_avatar


func set_max_health(value: float) -> void:
	max_health = max(0.0, value)

func get_max_health() -> float:
	return max_health


func set_speed(value: float) -> void:
	speed = max(0.0, value)

func get_speed() -> float:
	return speed


func set_attack_damage(value: float) -> void:
	attack_damage = max(0.0, value)

func get_attack_damage() -> float:
	return attack_damage


func set_attack_range(value: float) -> void:
	attack_range = max(0.0, value)

func get_attack_range() -> float:
	return attack_range


func set_base_recovery_delay(value: float) -> void:
	base_recovery_delay = max(0.0, value)

func get_base_recovery_delay() -> float:
	return base_recovery_delay


func set_base_attack_anim_duration(value: float) -> void:
	base_attack_anim_duration = max(0.0, value)

func get_base_attack_anim_duration() -> float:
	return base_attack_anim_duration


func set_defense(value: float) -> void:
	defense = max(0.0, value)

func get_defense() -> float:
	return defense


func set_resistance(value: float) -> void:
	resistance = max(0.0, value)

func get_resistance() -> float:
	return resistance


func set_custom_db_item_objects(value: Array[DataItem]) -> void:
	custom_db_item_objects = value

func get_custom_db_item_objects() -> Array[DataItem]:
	return custom_db_item_objects