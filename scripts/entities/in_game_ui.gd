extends Control


@onready var hero_avatar: TextureRect = %HeroAvatar
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var mana_bar: TextureProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
@onready var level_progress_bar: TextureProgressBar = $HeroContainer/Container/LevelProgressBar
@onready var level_label: Label = $HeroContainer/Container/Control/LevelLabel


func _ready():
	EventBus.initialize_hero_stats.connect(_initialize_hero_stats)
	

func _initialize_hero_stats(texture: Texture2D, max_health: float, max_mana: float, level: int, total_xp: int) -> void:
	_set_hero_avatar_texture(texture)
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	mana_bar.max_value = max_mana
	mana_bar.value = max_mana
	hp_label.text = "%s / %s" % [max_health, max_health]
	mana_label.text = "%s / %s" % [max_mana, max_mana]

	level_label.text = "%s" % [level]
	level_progress_bar.max_value = total_xp
	level_progress_bar.value = 0

	EventBus.update_hero_avatar_texture.connect(on_hero_avatar_texture)
	EventBus.update_hp_bar_value.connect(on_hp_bar_value)
	EventBus.update_mana_bar_value.connect(on_mana_bar_value)

	EventBus.level_up.connect(_on_level_up)
	EventBus.xp_changed.connect(_xp_changed)




func _on_level_up(new_level: int, total_xp: int) -> void:
	_set_level_label_text("%s" % [new_level])
	_set_level_progress_bar_max_value(total_xp)

func _xp_changed(current_xp: int) -> void:
	_set_level_progress_bar_value(current_xp)



func on_hero_avatar_texture(texture: Texture2D):
	_set_hero_avatar_texture(texture)


func on_hp_bar_value(value: float):
	_set_hp_bar_value(value)
	var text = "%s / %s" % [value, hp_bar.max_value]
	_set_hp_label_text(text)


func on_mana_bar_value(value: float):
	_set_mana_bar_value(value)
	var text = "%s / %s" % [value, mana_bar.max_value]
	_set_mana_label_text(text)


func _set_hero_avatar_texture(texture: Texture2D): hero_avatar.texture = texture


func _set_hp_bar_value(value: float): hp_bar.value = value


func _set_hp_label_text(text: String): hp_label.text = text


func _set_mana_bar_value(value: float): mana_bar.value = value


func _set_mana_label_text(text: String): mana_label.text = text

func _set_level_progress_bar_value(value: int): level_progress_bar.value = value

func _set_level_progress_bar_max_value(value: int): level_progress_bar.max_value = value

func _set_level_label_text(text: String): level_label.text = text
