extends Panel
class_name ItemCardDetails
@onready var item_name_label: Label = $VBoxContainer/Panel/MarginContainer/HBoxContainer/ItemNameLabel
@onready var player_class_label: Label = $VBoxContainer/Panel/MarginContainer/HBoxContainer/PlayerClassLabel
@onready var item_image_rect: TextureRect = $VBoxContainer/Panel2/HBoxContainer/ItemImage
@onready var item_type_label: Label = $VBoxContainer/Panel2/HBoxContainer/MarginContainer/VBoxContainer/ItemTypeLabel
@onready var item_rarety_label: Label = $VBoxContainer/Panel2/HBoxContainer/MarginContainer/VBoxContainer/IemRaretyLabel
@onready var item_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/ItemLevelLabel
@onready var price_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/PriceLabel
@onready var attribute_name_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/AttributeName
@onready var attribute_value_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/AttributeValue
@onready var item_upgrade_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ItemUpgradeLevelLabel
@onready var item_description_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/ItemDescriptionLabel

@export var data_item: DataItem

var item_name: String
var player_class_type: CharacterClass.PlayerType
var item_image: Texture2D
## TODO: Change it to ItemType instead of EquipementType
var item_type: Equipable.EquipementType
var item_category: Equipable.EquipmentCategory
var item_rarety: Item.Rarety
var item_lvl: String
var item_price: int
var item_attribute_name: String
var item_attribute_value: int
var item_upgrade_level: String
var item_description: String


func _ready() -> void:
	if data_item and data_item.item_name:
		item_name = data_item.item_name
		item_name_label.text = item_name
		item_name_label.visible = true
	else:
		item_name_label.visible = false

	if data_item and data_item.item_player_class:
		player_class_type = data_item.item_player_class
		player_class_label.text =str( CharacterClass.PlayerType.keys()[player_class_type])
		player_class_label.visible = true
	else:
		player_class_label.visible = false

	if  data_item and data_item.grid_coordinate != null:
		item_image = data_item.get_item_texture()
		item_image_rect.texture = item_image
		item_name_label.visible = true
	else:
		item_name_label.visible = false

	if data_item and data_item.item_type:
		item_type = data_item.item_type
		var type_str = Equipable.EquipementType.keys()[item_type]
		item_type_label.text =str(type_str)
		item_type_label.visible = true
	else:
		item_type_label.visible = false

	if item_rarety:
		item_rarety_label.text =str( Item.Rarety.keys()[item_rarety])
		item_rarety_label.visible = true
	else:
		item_rarety_label.visible = false

	if  data_item and data_item.required_level:
		item_lvl = str( data_item.required_level)
		item_level_label.text =str("Level: ", item_lvl)
		item_level_label.visible = true
	else:
		item_level_label.visible = false

	if  data_item and data_item.price:
		item_price = data_item.price
		price_label.text =str( item_price)
		price_label.visible = true
	else:
		price_label.visible = false

	if item_attribute_name:
		attribute_name_label.text =str( item_price)
		attribute_name_label.visible = true
	else:
		attribute_name_label.visible = false
	
	if item_attribute_value:
		attribute_value_label.text =str( item_attribute_value)
		attribute_value_label.visible = true
	else:
		attribute_value_label.visible = false
	
	if item_upgrade_level:
		item_upgrade_level_label.text =str( item_upgrade_level)
		item_upgrade_level_label.visible = true
	else:
		item_upgrade_level_label.visible = false

	if item_description:
		item_description_label.text =str(item_description)
		item_description_label.visible = true
	else:
		item_description_label.visible = false
