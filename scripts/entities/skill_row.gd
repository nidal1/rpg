extends Panel
class_name SkillRow
@onready var skill_name: Label = $HBoxContainer/VBoxContainer/HBoxContainer/SkillName
@onready var skill_level: Label = $HBoxContainer/VBoxContainer/HBoxContainer/SkillLevel
@onready var required_level: Label = $HBoxContainer/VBoxContainer/HBoxContainer2/RequiredLevel
@onready var skill_points_cost: Label = $HBoxContainer/VBoxContainer2/HBoxContainer/SkillPointsCost
@onready var add_button: Button = $HBoxContainer/AddButton
@onready var skill_texture: TextureRect = $HBoxContainer/Container/MarginContainer/SkillTexture

var skill_data : Skill

func _ready() -> void:
	if skill_data:
		skill_texture.texture = skill_data.skill_icon
		skill_name.text = str(skill_data.skill_name)
		skill_level.text = str(skill_data.level)
		required_level.text = str(skill_data.required_player_level)
		skill_points_cost.text = str(skill_data.skill_points_cost)
		tooltip_text = skill_data.description
