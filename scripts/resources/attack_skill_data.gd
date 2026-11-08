extends Skill
class_name AttackSkill

enum TargetType {
	enemy,
	aoe,
}

#Crowd Control Damage
enum CrowdControl {
	stun, #(صعق / شلل)
	silence, #(إسكات)
	bind, #(تثبيت فالمكان)
	bleeding,# (نزيف)
	burn, #(احتراق),
	blind, #(عمى مؤقت)
	slow, #(إبطاء السرعة),
	none
}

# targeting and range
@export var skill_target_type: TargetType = TargetType.enemy
@export var skill_range: float

#Combat & Effects
@export var damage: float
@export var cc_effect: CrowdControl
@export var cc_duration: float