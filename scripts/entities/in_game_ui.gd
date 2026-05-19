extends Control

signal hero_avatar_texture(texture: Texture2D)
signal hp_bar_value(value: float)
signal hp_label_text(text: String)
signal mana_bar_value(value: float)
signal mana_label_text(text: String)

@onready var hero_avatar: TextureRect = %HeroAvatar
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var mana_bar: TextureProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel


func _ready():
	hero_avatar_texture.connect(on_hero_avatar_texture)
	hp_bar_value.connect(on_hp_bar_value)
	hp_label_text.connect(on_hp_label_text)
	mana_bar_value.connect(on_mana_bar_value)
	mana_label_text.connect(on_mana_label_text)


func on_hero_avatar_texture(texture: Texture2D):
	_set_hero_avatar_texture(texture)


func on_hp_bar_value(value: float):
	_set_hp_bar_value(value)


func on_hp_label_text(text: String):
	_set_hp_label_text(text)


func on_mana_bar_value(value: float):
	_set_mana_bar_value(value)


func on_mana_label_text(text: String):
	_set_mana_label_text(text)


func _set_hero_avatar_texture(texture: Texture2D): hero_avatar.texture = texture


func _set_hp_bar_value(value: float): hp_bar.value = value


func _set_hp_label_text(text: String): hp_label.text = text


func _set_mana_bar_value(value: float): mana_bar.value = value


func _set_mana_label_text(text: String): mana_label.text = text