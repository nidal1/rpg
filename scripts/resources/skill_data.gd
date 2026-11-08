extends Resource
class_name Skill

# basic info
@export var skill_id : String
@export var skill_name : String
@export var description : String
@export var skill_icon : Texture2D
@export var skill_owner: Array[CharacterClass.PlayerType]

# Costs & Timings
@export var mp_cost: int
@export var cast_time: float
@export var cooldown: float

# Progression & Requirements
@export var level: int
@export var max_level: int
@export var required_player_level: int
@export var skill_points_cost: int