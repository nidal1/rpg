extends HBoxContainer
class_name ItemStatsRow

@onready var item_stats_key_label: Label = $ItemStatsKeyLabel
@onready var item_stats_value_label: Label = $ItemStatsValueLabel
@onready var item_stats_upgrade_label: Label = $ItemStatsUpgradeLabel

func set_stats_row_key(key: String) -> void:
	item_stats_key_label.text = key

func set_stats_row_value(value: int) -> void:
	item_stats_value_label.text = str(value)

func set_stats_row_upgrade(upgrade: int) -> void:
	if upgrade > 0:
		item_stats_upgrade_label.text = "+" + str(upgrade)
	else:
		item_stats_upgrade_label.text = ""

func set_stats_row(key: String, value: int, upgrade: int = 0) -> void:
	set_stats_row_key(key)
	set_stats_row_value(value)
	set_stats_row_upgrade(upgrade)
