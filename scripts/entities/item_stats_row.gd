extends HBoxContainer
class_name ItemStatsRow

@onready var item_stats_key_label: Label = $ItemStatsKeyLabel
@onready var item_stats_value_label: Label = $ItemStatsValueLabel
@onready var item_stats_upgrade_label: Label = $ItemStatsUpgradeLabel

func set_stats_row_key(key: String) -> void:
	item_stats_key_label.text = key

func set_stats_row_value(value: String) -> void:
	item_stats_value_label.text = value

func set_stats_row_upgrade(upgrade: String) -> void:
	item_stats_upgrade_label.text = upgrade

func set_stats_row(key: String, value: String, upgrade: String) -> void:
	set_stats_row_key(key)
	set_stats_row_value(value)
	set_stats_row_upgrade(upgrade)
