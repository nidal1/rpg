extends Resource
class_name Skill

# basic info
@export var skill_id : String
@export var skill_name : String
@export var base_description: String :  # الوصف الأصلي لي فيه #value#
	set(val):
		base_description = val
		notify_property_list_changed()
@export var description : String:
	get:
		var desc: String = base_description
		var val = str(get_value())
		if desc.contains("#value#"):
			desc = desc.replace("#value#", val)
		return desc

@export var skill_icon : Texture2D
@export var skill_owner: Array[CharacterClass.PlayerType]

# Costs & Timings
@export var mp_cost: int
@export var cast_time: float
@export var cooldown: float

# Progression & Requirements
@export var level: int
@export var max_level: int
@export var required_player_level: Array[int]
@export var skill_points_cost: int

@export var skill_disabled = false:
	get:
		self.check_skill_requirements()
		return skill_disabled

func check_skill_requirements():
	if PlayerData:
		var lacks_max_level = level == max_level

		var lacks_sp = PlayerData.get_player_current_skills_points() < skill_points_cost

		var lacks_level = PlayerData.get_player_level() != required_player_level[level]

		self.skill_disabled = lacks_max_level or lacks_sp or lacks_level

func get_value() -> float:
	return 0.0


func stringify() -> String:
	var icon_info = "None"
	if skill_icon and skill_icon.resource_path != "":
		icon_info = skill_icon.resource_path
		
	var data_dict = {
		"skill_id": skill_id,
		"skill_name": skill_name,
		"level": str(level) + "/" + str(max_level),
		"mp_cost": mp_cost,
		"cooldown": cooldown,
		"cast_time": cast_time,
		"required_player_level": required_player_level,
		"skill_points_cost": skill_points_cost,
		"skill_disabled": skill_disabled,
		"icon_path": icon_info
	}
	
	return JSON.stringify(data_dict, "\t")
