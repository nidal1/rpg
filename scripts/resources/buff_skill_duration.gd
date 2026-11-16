extends Node
class_name BuffSkillDuration

		
@export var skill: BuffSkill
@export var value: float

func _init(_skill: BuffSkill, _value: float) -> void:
	skill = _skill
	value = _value
	
func _ready() -> void:
	await get_tree().create_timer(skill.duration).timeout

	EventBus.buff_skill_duration_ended.emit(skill, value)

	queue_free()
