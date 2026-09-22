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


func _ready() -> void:
	if not data_item:
		return

	# Base Properties
	if data_item.item_name != "":
		item_name_label.text = data_item.item_name
		item_name_label.visible = true
	else:
		item_name_label.visible = false

	var tex = data_item.get_item_texture()
	if tex:
		item_image_rect.texture = tex
		item_image_rect.visible = true
	else:
		item_image_rect.visible = false

	if data_item.price > 0:
		price_label.text = str(data_item.price) + " Gold"
		price_label.visible = true
	else:
		price_label.visible = false

	# Type-specific Properties
	if data_item is EquipableItem:
		var eq = data_item as EquipableItem
		if eq.player_class != "":
			player_class_label.text = eq.player_class
			player_class_label.visible = true
		else:
			player_class_label.visible = false

		if eq.equipment_type != "":
			item_type_label.text = eq.equipment_type
			item_type_label.visible = true
		else:
			item_type_label.visible = false

		if eq.required_level > 0:
			item_level_label.text = "Level: " + str(eq.required_level)
			item_level_label.visible = true
		else:
			item_level_label.visible = false

		if eq.base_damage > 0:
			attribute_name_label.text = "Base Damage"
			attribute_value_label.text = str(eq.base_damage)
			attribute_name_label.visible = true
			attribute_value_label.visible = true
		elif eq.base_defense > 0:
			attribute_name_label.text = "Base Defense"
			attribute_value_label.text = str(eq.base_defense)
			attribute_name_label.visible = true
			attribute_value_label.visible = true
		else:
			attribute_name_label.visible = false
			attribute_value_label.visible = false

	elif data_item is ConsumableItem:
		var cons = data_item as ConsumableItem
		player_class_label.visible = false
		item_type_label.text = cons.potion_type + " POTION"
		item_type_label.visible = true
		item_level_label.visible = false

		if cons.heal_amount > 0:
			attribute_name_label.text = "Heal Amount"
			attribute_value_label.text = str(cons.heal_amount)
			attribute_name_label.visible = true
			attribute_value_label.visible = true
		else:
			attribute_name_label.visible = false
			attribute_value_label.visible = false

	elif data_item is QuestItem:
		var q = data_item as QuestItem
		player_class_label.visible = false
		item_type_label.text = "QUEST ITEM"
		item_type_label.visible = true
		item_level_label.visible = false
		attribute_name_label.visible = false
		attribute_value_label.visible = false

		if q.description != "":
			item_description_label.text = q.description
			item_description_label.visible = true
		else:
			item_description_label.visible = false
	else:
		player_class_label.visible = false
		item_type_label.visible = false
		item_level_label.visible = false
		attribute_name_label.visible = false
		attribute_value_label.visible = false

	item_rarety_label.visible = false
	item_upgrade_level_label.visible = false
