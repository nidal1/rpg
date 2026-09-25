extends Panel
class_name EquipableTableDetails

var equipable_item: EquipableItem

@export var item_stats_row_scene: PackedScene
@export var gem_slot_scene: PackedScene

@onready var item_name_label: Label = $VBoxContainer/Panel/MarginContainer/HBoxContainer/ItemNameLabel
@onready var player_class_label: Label = $VBoxContainer/Panel/MarginContainer/HBoxContainer/PlayerClassLabel
@onready var item_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/ItemLevelLabel
@onready var item_image: TextureRect = $VBoxContainer/Panel2/HBoxContainer/ItemImage
@onready var item_category_label: Label = $VBoxContainer/Panel2/HBoxContainer/MarginContainer/VBoxContainer/ItemCategoryLabel
@onready var iem_rarety_label: Label = $VBoxContainer/Panel2/HBoxContainer/MarginContainer/VBoxContainer/IemRaretyLabel
@onready var item_stats_container: VBoxContainer = $VBoxContainer/MarginContainer/VBoxContainer/ItemStatsContainer
@onready var tradablity_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/TradablityLabel
@onready var item_description_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/ItemDescriptionLabel
@onready var gems_slots_container: HBoxContainer = $VBoxContainer/Panel3/MarginContainer/GemsSlotsContainer
@onready var price_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/PriceLabel

func set_equipable_item(_equipable_item: EquipableItem) -> void:
	equipable_item = _equipable_item
	if equipable_item == null:
		return
	_set_item_name(equipable_item.item_name)
	_set_player_class(equipable_item.player_class)
	_set_item_level_label(str(equipable_item.required_level))
	_set_item_image(equipable_item.get_item_texture())
	_set_item_category_label(equipable_item.equipment_type)
	_set_item_prince_label(equipable_item.price)

func _set_item_name(_item_name: String) -> void:
	if item_name_label: item_name_label.text = _item_name

func _set_player_class(_player_class: String) -> void:
	if player_class_label: player_class_label.text = _player_class

func _set_item_level_label(_item_level: String) -> void:
	if item_level_label: item_level_label.text = "Level: " + _item_level

func _set_item_image(_item_image: Texture2D) -> void:
	if item_image != null and _item_image != null:
		item_image.texture = _item_image

func _set_item_category_label(_item_category: String) -> void:
	if item_category_label: item_category_label.text = _item_category

func _set_item_prince_label(_item_price: int) -> void:
	if iem_rarety_label: iem_rarety_label.text = str(_item_price)
	if price_label: price_label.text = str(_item_price)
