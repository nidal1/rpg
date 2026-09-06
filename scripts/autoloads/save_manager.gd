## SaveManager
## Autoload that handles saving and loading the player's progress and game state.
extends Node

const DEFAULT_SAVE_PATH = "user://save_game.json"

## Emitted when game save completes successfully.
signal game_saved()
## Emitted when game load completes successfully.
signal game_loaded()

## Checks if a save file exists.
func has_save_game(filepath: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(filepath)

## Saves the player's level, XP, stat allocation, and base stats to a JSON file.
func save_game(filepath: String = DEFAULT_SAVE_PATH) -> Error:
	var base_stats = PlayerData.get_base_stats()
	var save_data = {
		"level": PlayerData.get_player_level(),
		"current_xp": PlayerData.get_current_xp(),
		"total_xp_to_next_level": PlayerData.get_total_xp_to_next_level(),
		"stat_points_available": PlayerData.get_stat_points_available(),
		"allocated_stats": PlayerData.get_stat_alloc(),
		"base_stats": base_stats.to_dict() if base_stats else {}
	}
	
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		printerr("SaveManager: Failed to open save file for writing: ", err)
		return err
		
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	print("SaveManager: Game successfully saved to ", filepath)
	game_saved.emit()
	return OK

## Loads the player's level, XP, stat allocation, and base stats from a JSON file.
func load_game(filepath: String = DEFAULT_SAVE_PATH) -> Error:
	if not has_save_game(filepath):
		printerr("SaveManager: Save file does not exist at ", filepath)
		return ERR_FILE_NOT_FOUND
		
	var file = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		var err = FileAccess.get_open_error()
		printerr("SaveManager: Failed to open save file for reading: ", err)
		return err
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		printerr("SaveManager: Failed to parse save JSON: ", json.get_error_message())
		return parse_result
		
	var save_data = json.data
	if not save_data is Dictionary:
		return ERR_INVALID_DATA
		
	if save_data.has("level"):
		PlayerData.set_player_level(save_data["level"])
	if save_data.has("current_xp"):
		PlayerData.set_current_xp(save_data["current_xp"])
	if save_data.has("total_xp_to_next_level"):
		PlayerData.set_total_xp_to_next_level(save_data["total_xp_to_next_level"])
	if save_data.has("stat_points_available"):
		PlayerData.set_stat_points_available(save_data["stat_points_available"])
		
	if save_data.has("allocated_stats") and save_data["allocated_stats"] is Dictionary:
		for stat_name in save_data["allocated_stats"]:
			PlayerData.set_allocated_stat(stat_name, int(save_data["allocated_stats"][stat_name]))
			
	var base_stats = PlayerData.get_base_stats()
	if base_stats and save_data.has("base_stats") and save_data["base_stats"] is Dictionary:
		base_stats.from_dict_to_base_stats(save_data["base_stats"])
		
	PlayerData.save_stats()
	EventBus.hero_stats_changed.emit(base_stats)
	EventBus.stat_points_available_changed.emit(PlayerData.get_stat_points_available())
	print("SaveManager: Game successfully loaded from ", filepath)
	game_loaded.emit()
	return OK
