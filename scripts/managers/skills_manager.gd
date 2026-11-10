class_name SkillsManager
extends Node

## Number of skills points awarded per level up.
const SKILLS_POINTS_PER_LEVEL = 3

var skill_database_loader: SkillsDatabaseLoader = SkillsDatabaseLoader.new()
var player_character_class : String

var passive_skills: Array[PassiveSkill] = []
var buff_skills: Array[BuffSkill] = []
var attack_skills: Array[AttackSkill] = []

func initialize(character_class : CharacterClass) -> void:
	player_character_class = str(CharacterClass.PlayerType.keys()[character_class.player_type]).to_lower()

	attack_skills = skill_database_loader.loaded_skills[player_character_class]["attack"] as Array[AttackSkill]

	passive_skills = skill_database_loader.loaded_skills[player_character_class]["passive"] as Array[PassiveSkill]

	buff_skills = skill_database_loader.loaded_skills[player_character_class]["buff"] as Array[BuffSkill]

	update_player_current_skills_points_on_level_up()

	EventBus.upgrade_skill.connect(_on_upgrade_skill)

func update_player_current_skills_points_on_level_up():
	var available_skills_points = SkillsData.get_player_current_skills_points() + SKILLS_POINTS_PER_LEVEL

	SkillsData.set_player_current_skills_points(available_skills_points)

func _on_upgrade_skill(_skill: Skill):
	var available_skills_points = SkillsData.get_player_current_skills_points()
	if available_skills_points >= _skill.skill_points_cost:
		SkillsData.remove_player_upgraded_skill_exist(_skill)
		_skill.level += 1
		SkillsData.set_player_current_skills_points(available_skills_points -  _skill.skill_points_cost)
		SkillsData.set_player_upgraded_skills(_skill)
	else:
		push_error("available_skills_points smaller than the skill points cost")
