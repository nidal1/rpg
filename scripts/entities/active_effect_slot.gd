extends VBoxContainer
class_name ActiveEffectSlot

@onready var active_effect_texture: TextureRect = $CenterContainer/ActiveEffectTexture
@onready var cd_active_effect: TextureProgressBar = $CDActiveEffect
@onready var cd_active_effect_timer: Timer = $CDActiveEffectTimer

var current_skill: Skill
var cd_started = false

func _ready() -> void:
	if current_skill:
		active_effect_texture.texture = current_skill.skill_icon
		var cd = current_skill.duration
		cd_active_effect_timer.wait_time = cd
		cd_active_effect_timer.start()
		cd_started = true
	

func _physics_process(_delta: float) -> void:
	if cd_started and cd_active_effect_timer.time_left > 0:
		var cd_amout = (cd_active_effect_timer.time_left / cd_active_effect_timer.wait_time) * 100
		cd_active_effect.value = cd_amout

func set_slot(_skill: Skill):
	current_skill = _skill



func _on_cd_active_effect_timer_timeout() -> void:
	cd_started = false
	queue_free()
