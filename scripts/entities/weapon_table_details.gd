extends EquipableTableDetails
class_name WeaponTableDetails


var __atk_upgrade_color: Color = Color("#ff5b00")
var __atk_normal_color: Color = Color("#ffffff")

@onready var attack_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/AttackLabel
@onready var item_upgrade_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ItemUpgradeLevelLabel

func set_equipable_item(_equipable_item: Equipable) -> void:
	super.set_equipable_item(_equipable_item)
	_set_attack_label(str(int(_equipable_item.get_total_attack_power())))
	_set_item_upgrade_level_label(str(_equipable_item.upgrade_level))


func _set_attack_label(_attack: String) -> void:
	attack_label.text = _attack

func _set_item_upgrade_level_label(_item_upgrade_level: String) -> void:
	if _item_upgrade_level == "0":
		attack_label.add_theme_color_override("font_color", __atk_normal_color)
	else:
		item_upgrade_level_label.text = str("+" + _item_upgrade_level)
		attack_label.add_theme_color_override("font_color", __atk_upgrade_color)
