extends Node


var level_scaler = 1.2

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


# leveling -----------------------------------------
func _on_enemy_died(enemy: Enemy) -> void:
	var xp_reward = enemy.enemy_params.xp_reward
	if xp_reward > 0:
		add_xp(xp_reward)

func add_xp(amount: int) -> void:
	var current_xp = PlayerData.get_current_xp() + amount
	PlayerData.set_current_xp(current_xp)
	EventBus.xp_changed.emit(current_xp)
	if current_xp >= PlayerData.get_total_xp_to_next_level():
		level_up()

func level_up() -> void:

	var player_level = PlayerData.get_player_level() + 1
	PlayerData.set_player_level(player_level)

	scalling_level_up()
	EventBus.level_up.emit(player_level, PlayerData.get_total_xp_to_next_level())

func scalling_level_up() -> void:
	PlayerData.set_total_xp_to_next_level(int(level_scaler * PlayerData.get_total_xp_to_next_level()))
