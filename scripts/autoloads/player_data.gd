extends Node


var __player_level: int = 1
var __current_xp: int = 0
var __total_xp_to_next_level: int = 75

func set_player_level(new_level: int) -> void:
	__player_level = new_level

func get_player_level() -> int:
	return __player_level

func set_current_xp(new_xp: int) -> void:
	__current_xp = new_xp

func get_current_xp() -> int:
	return __current_xp

func set_total_xp_to_next_level(new_xp: int) -> void:
	__total_xp_to_next_level = new_xp

func get_total_xp_to_next_level() -> int:
	return __total_xp_to_next_level
