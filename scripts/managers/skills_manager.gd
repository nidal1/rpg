class_name SkillsManager
extends Node

var skill_database_loader: SkillsDatabaseLoader = SkillsDatabaseLoader.new()
var player_character_class : String

var passive_skills = []
var buff_skills = []
var attack_skills = []

func initialize(character_class : CharacterClass) -> void:
	player_character_class = str(CharacterClass.PlayerType.keys()[character_class.player_type]).to_lower()

	attack_skills = skill_database_loader.loaded_skills[player_character_class]["attack"]

	passive_skills = skill_database_loader.loaded_skills[player_character_class]["passive"]

	buff_skills = skill_database_loader.loaded_skills[player_character_class]["buff"]
