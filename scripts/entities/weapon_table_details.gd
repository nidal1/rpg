extends Panel
class_name WeaponTableDetails

@export var item_stats_row_scene: PackedScene
@export var gem_slot_scene: PackedScene

@onready var item_name_label: Label = $VBoxContainer/Panel/MarginContainer/HBoxContainer/ItemNameLabel
@onready var player_class_label: Label = $VBoxContainer/Panel/MarginContainer/HBoxContainer/PlayerClassLabel
@onready var item_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/ItemLevelLabel
@onready var attack_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/AttackLabel
@onready var item_upgrade_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ItemUpgradeLevelLabel
@onready var item_image: TextureRect = $VBoxContainer/Panel2/HBoxContainer/ItemImage
@onready var item_category_label: Label = $VBoxContainer/Panel2/HBoxContainer/MarginContainer/VBoxContainer/ItemCategoryLabel
@onready var iem_rarety_label: Label = $VBoxContainer/Panel2/HBoxContainer/MarginContainer/VBoxContainer/IemRaretyLabel
@onready var item_stats_container: VBoxContainer = $VBoxContainer/MarginContainer/VBoxContainer/ItemStatsContainer
@onready var tradablity_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/TradablityLabel
@onready var item_description_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/ItemDescriptionLabel
@onready var gems_slots_container: HBoxContainer = $VBoxContainer/Panel3/MarginContainer/GemsSlotsContainer


var weapon_item: Weapon
var __atk_upgrade_color: Color = Color("#ff5b00")
var __atk_normal_color: Color = Color("#ffffff")

func set_weapon_item(_weapon_item: Weapon) -> void:
	weapon_item = _weapon_item
	_set_item_name(weapon_item.item_name)
	_set_player_class(CharacterClass.PlayerType.keys()[weapon_item.player_type])
	_set_item_level_label(str(weapon_item.level))
	_set_attack_label(str(int(weapon_item.get_total_attack_power())))
	_set_item_upgrade_level_label(str(weapon_item.upgrade_level))
	_set_item_image(weapon_item.icon)
	_set_item_category_label(Item.ItemType.keys()[weapon_item.item_type])
	_set_item_rarety_label(Item.Rarety.keys()[weapon_item.rarety])
	# _set_item_stats_rows(weapon_item.stats)
	# _set_tradablity(weapon_item.tradable)
	_set_item_description(weapon_item.description)
	_set_gem_slots(weapon_item.gems_slots_count)
	_set_gems_in_slots(weapon_item.gems)

func _set_item_name(_item_name: String) -> void:
	item_name_label.text = _item_name

func _set_player_class(_player_class: String) -> void:
	player_class_label.text = _player_class

func _set_item_level_label(_item_level: String) -> void:
	item_level_label.text = "Level: " + _item_level

func _set_attack_label(_attack: String) -> void:
	attack_label.text = _attack

func _set_item_upgrade_level_label(_item_upgrade_level: String) -> void:
	if _item_upgrade_level == "0":
		attack_label.add_theme_color_override("font_color", __atk_normal_color)
	else:
		item_upgrade_level_label.text = str("+" + _item_upgrade_level)
		attack_label.add_theme_color_override("font_color", __atk_upgrade_color)

func _set_item_image(_item_image: Texture2D) -> void:
	if _item_image != null:
		item_image.texture = _item_image

func _set_item_category_label(_item_category: String) -> void:
	item_category_label.text = _item_category

func _set_item_rarety_label(_item_rarety: String) -> void:
	iem_rarety_label.text = _item_rarety

func _set_item_stats_rows(_item_stats: Array) -> void:
	item_stats_container.clear()
	for item_stat in _item_stats:
		var item_stats_row = item_stats_row_scene.instantiate()
		item_stats_row.set_stats_row(item_stat.key, item_stat.value, item_stat.upgrade)
		item_stats_container.add_child(item_stats_row)

func _set_tradablity(_tradablity: bool) -> void:
	if _tradablity:
		tradablity_label.text = "Tradable"
	else:
		tradablity_label.text = "Untradable"

func _set_item_description(_item_description: String) -> void:
	item_description_label.text = _item_description

func _set_gem_slots(_gem_slots_count: int) -> void:
	for i in range(_gem_slots_count):
		var gem_slot_instance = gem_slot_scene.instantiate()
		gems_slots_container.add_child(gem_slot_instance)

func _set_gems_in_slots(_gems: Array[Gem]) -> void:
	if _gems.size() == 0:
		return
	var slots = gems_slots_container.get_children()
	for i in range(_gems.size()):
		slots[i].set_gem_image(_gems[i].icon)
