extends EquipableTableDetails
class_name ArmorTableDetails

@onready var defense_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/DefenseLabel
@onready var item_upgrade_defense_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ItemUpgradeDefenseLevelLabel
@onready var resistanse_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/ResistanseLabel
@onready var item_upgrade_resistance_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/ItemUpgradeResistanceLevelLabel


var __def_resist_upgrade_color: Color = Color("#ff5b00")
var __def_resist_normal_color: Color = Color("#ffffff")

func set_equipable_item(_equipable_item: Equipable) -> void:
	super.set_equipable_item(_equipable_item)
	_set_defense_label(str(int(_equipable_item.get_total_defense())))
	_set_item_upgrade_defense_level_label(str(_equipable_item.upgrade_level))
	_set_resistance_label(str(int(_equipable_item.get_total_resistance())))
	_set_item_upgrade_resistance_level_label(str(_equipable_item.upgrade_resistance_level))

func _set_defense_label(_defense: String) -> void:
	defense_label.text = _defense

func _set_item_upgrade_defense_level_label(_item_upgrade_defense_level: String) -> void:
	if _item_upgrade_defense_level == "0":
		defense_label.add_theme_color_override("font_color", __def_resist_normal_color)
	else:
		item_upgrade_defense_level_label.text = str("+" + _item_upgrade_defense_level)
		defense_label.add_theme_color_override("font_color", __def_resist_upgrade_color)

func _set_resistance_label(_resistance: String) -> void:
	resistanse_label.text = _resistance

func _set_item_upgrade_resistance_level_label(_item_upgrade_resistance_level: String) -> void:
	if _item_upgrade_resistance_level == "0":
		resistanse_label.add_theme_color_override("font_color", __def_resist_normal_color)
	else:
		item_upgrade_resistance_level_label.text = str("+" + _item_upgrade_resistance_level)
		resistanse_label.add_theme_color_override("font_color", __def_resist_upgrade_color)
