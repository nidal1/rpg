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
	EventBus.upgrade_skill.connect(_on_upgrade_skill)
	if skill_data:
		skill_texture.texture = skill_data.skill_icon
		skill_name.text = str(skill_data.skill_name)
		skill_level.text = str(skill_data.level)
		required_level.text = str(skill_data.required_player_level[skill_data.level])
		skill_points_cost.text = str(skill_data.skill_points_cost)
		tooltip_text = skill_data.description

func toggle_button(_disabled: bool):
	add_button.disabled = _disabled

func set_skill_data(_value: Skill):
	if _value and skill_texture and skill_name and skill_level and required_level and skill_points_cost :
			skill_texture.texture = _value.skill_icon
			skill_name.text = str(_value.skill_name)
			skill_level.text = str(_value.level)
			required_level.text = str(_value.required_player_level[_value.level])
			skill_points_cost.text = str(_value.skill_points_cost)
			tooltip_text = _value.description

func _on_add_button_pressed() -> void:
	EventBus.upgrade_skill.emit(skill_data)

func _on_upgrade_skill(_skill: Skill):
	if skill_data.skill_id == _skill.skill_id:
		set_skill_data(_skill)
		toggle_button(skill_data.skill_disabled)
