extends EquipableTableDetails
class_name WeaponTableDetails


var __atk_upgrade_color: Color = Color("#ff5b00")
var __atk_normal_color: Color = Color("#ffffff")

@onready var attack_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/AttackLabel
@onready var item_upgrade_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ItemUpgradeLevelLabel

func set_equipable_item(_equipable_item: EquipableItem) -> void:
	super.set_equipable_item(_equipable_item)
	if _equipable_item:
		_set_attack_label(str(_equipable_item.base_damage))


func _set_attack_label(_attack: String) -> void:
	if attack_label: attack_label.text = _attack

func _set_item_upgrade_level_label(_item_upgrade_level: String) -> void:
	if _item_upgrade_level == "0":
		if attack_label: attack_label.add_theme_color_override("font_color", __atk_normal_color)
	else:
		if item_upgrade_level_label: item_upgrade_level_label.text = str("+" + _item_upgrade_level)
		if attack_label: attack_label.add_theme_color_override("font_color", __atk_upgrade_color)
