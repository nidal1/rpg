extends Panel
class_name SkillSlot

@onready var texture_button: TextureButton = $TextureButton
@onready var cd_progress_bar: TextureProgressBar = $CDProgressBar
@onready var cd_timer: Timer = $CDTimer
@onready var cd_time_left_label: Label = $CDTimeLeftLabel

var is_empty = true
var cd_started = false
var current_skill: Skill

func _ready() -> void:
	EventBus.buff_skill_duration_started.connect(_on_buff_skill_duration_started)
	EventBus.attack_skill_cd_started.connect(_on_attack_skill_cd_started)
	disable_progress_bar()

func _physics_process(_delta: float) -> void:
	if cd_started and cd_timer.time_left > 0:
		var cd_amout = (cd_timer.time_left / cd_timer.wait_time) * 100
		cd_progress_bar.value = cd_amout
		cd_time_left_label.text = str(snapped(cd_timer.time_left, 0.1))

func set_slot(_skill: Skill):
	current_skill = _skill
	if _skill != null:
		is_empty = false
		texture_button.tooltip_text = current_skill.description
		
		if current_skill.skill_icon:
			texture_button.texture_normal = current_skill.skill_icon

func clear_slot():
	current_skill = null
	is_empty = false
	tooltip_text = ""

func disable_progress_bar():
	cd_progress_bar.visible = false
	cd_progress_bar.value = 100.0
	cd_progress_bar.z_index = -1
	texture_button.disabled = false
	cd_time_left_label.visible = false
	cd_time_left_label.z_index = -1
	if current_skill:
		texture_button.tooltip_text = current_skill.description

func enable_progress_bar():
	cd_progress_bar.visible = true
	cd_progress_bar.z_index = 0
	texture_button.disabled = true
	cd_time_left_label.visible = true
	cd_time_left_label.z_index = 0
	if current_skill:
		texture_button.tooltip_text = current_skill.description

func _on_texture_button_pressed() -> void:
	enable_progress_bar()
	if current_skill:
		if not current_skill.can_cast_skill():
			disable_progress_bar()
			print("player mp less than the skill mp cost")
			return
		
		EventBus.skill_slot_clicked.emit(current_skill, self)


func _on_buff_skill_duration_started(_skill: Skill, _value: float):
	var cd = _skill.cooldown
	cd_timer.wait_time = cd
	cd_timer.start()
	cd_started = true

func _on_attack_skill_cd_started(_skill: Skill):
	var cd = _skill.cooldown
	cd_timer.wait_time = cd
	cd_timer.start()
	cd_started = true

func _on_cd_timer_timeout() -> void:
	cd_started = false
	disable_progress_bar()
