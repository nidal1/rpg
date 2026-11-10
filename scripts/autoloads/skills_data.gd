## SkillsData
## Autoload that stores and manages the player's skills, upgraded skills, and skills points.
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
## Number of skill points awarded per level up.
const SKILLS_POINTS_PER_LEVEL = 3

# ─── Private Variables ───────────────────────────────────────────────────────
var __current_skills_points: int = 0

var __player_upgraded_skills = {
	"passive": [] as Array[PassiveSkill],
	"attack": [] as Array[AttackSkill],
	"buff": [] as Array[BuffSkill],
}

# ─── Skills ───────────────────────────────────────────────────────────────

## Sets the list of upgraded skills.
func set_player_upgraded_skills(_skill: Skill):
	if _skill is AttackSkill:
		__player_upgraded_skills["attack"].append(_skill)
	
	elif _skill is PassiveSkill:
		__player_upgraded_skills["passive"].append(_skill)
	
	elif _skill is BuffSkill:
		__player_upgraded_skills["buff"].append(_skill)

func get_player_upgraded_skills():
	return __player_upgraded_skills

## Checks if a specific skill exists in the upgraded list.
func player_upgraded_skill_exist(_skill: Skill) -> bool:
	if _skill is AttackSkill and (_skill in __player_upgraded_skills["attack"]):
		return true
	elif _skill is PassiveSkill and (_skill in __player_upgraded_skills["passive"]):
		return true
	elif _skill is BuffSkill and (_skill in __player_upgraded_skills["buff"]):
		return true
	return false

## Removes a skill from the upgraded list.
func remove_player_upgraded_skill_exist(_skill: Skill) -> void:
	if not player_upgraded_skill_exist(_skill):
		return

	if _skill is AttackSkill and (_skill in __player_upgraded_skills["attack"]):
		__player_upgraded_skills["attack"].erase(_skill)
	elif _skill is PassiveSkill and (_skill in __player_upgraded_skills["passive"]):
		__player_upgraded_skills["passive"].erase(_skill)
	elif _skill is BuffSkill and (_skill in __player_upgraded_skills["buff"]):
		__player_upgraded_skills["buff"].erase(_skill)

## Gets the current skills points.
func get_player_current_skills_points() -> int:
	return __current_skills_points

## Sets the current skills points.
func set_player_current_skills_points(_points: int) -> void:
	__current_skills_points = _points
