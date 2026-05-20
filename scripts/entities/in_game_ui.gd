extends Control


@onready var hero_avatar: TextureRect = %HeroAvatar
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var mana_bar: TextureProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel


func _ready():
	EventBus.initialize_hero_stats.connect(initialize_hero)
	

func initialize_hero(texture: Texture2D, max_health: float, max_mana: float) -> void:
	_set_hero_avatar_texture(texture)
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	mana_bar.max_value = max_mana
	mana_bar.value = max_mana
	hp_label.text = "%s / %s" % [max_health, max_health]
	mana_label.text = "%s / %s" % [max_mana, max_mana]

	EventBus.update_hero_avatar_texture.connect(on_hero_avatar_texture)
	EventBus.update_hp_bar_value.connect(on_hp_bar_value)
	EventBus.update_mana_bar_value.connect(on_mana_bar_value)


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
