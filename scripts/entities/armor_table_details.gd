extends EquipableTableDetails
class_name ArmorTableDetails

@onready var defense_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/DefenseLabel
@onready var item_upgrade_defense_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ItemUpgradeDefenseLevelLabel
@onready var resistanse_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/ResistanseLabel
@onready var item_upgrade_resistance_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/ItemUpgradeResistanceLevelLabel


var __def_resist_upgrade_color: Color = Color("#ff5b00")
var __def_resist_normal_color: Color = Color("#ffffff")

func set_equipable_item(_equipable_item: EquipableItem) -> void:
	super.set_equipable_item(_equipable_item)
	if _equipable_item:
		_set_defense_label(str(_equipable_item.base_defense))

func _set_defense_label(_defense: String) -> void:
	if defense_label: defense_label.text = _defense

func _set_item_upgrade_defense_level_label(_item_upgrade_defense_level: String) -> void:
	if _item_upgrade_defense_level == "0":
		if defense_label: defense_label.add_theme_color_override("font_color", __def_resist_normal_color)
	else:
		if item_upgrade_defense_level_label: item_upgrade_defense_level_label.text = str("+" + _item_upgrade_defense_level)
		if defense_label: defense_label.add_theme_color_override("font_color", __def_resist_upgrade_color)

func _set_resistance_label(_resistance: String) -> void:
	if resistanse_label: resistanse_label.text = _resistance

func _set_item_upgrade_resistance_level_label(_item_upgrade_resistance_level: String) -> void:
	if _item_upgrade_resistance_level == "0":
		if resistanse_label: resistanse_label.add_theme_color_override("font_color", __def_resist_normal_color)
	else:
		if item_upgrade_resistance_level_label: item_upgrade_resistance_level_label.text = str("+" + _item_upgrade_resistance_level)
		if resistanse_label: resistanse_label.add_theme_color_override("font_color", __def_resist_upgrade_color)
