extends HBoxContainer
class_name StatContainer

@onready var stat_name_label: Label = $StatNameLabel
@onready var stat_point_label: Label = $StatPointLabel
@onready var add_stat_point_button: Button = $AddStatPointButton
@onready var sub_stat_point_button: Button = $SubStatPointButton

var stat_name: String = ""

func set_stat_name(_name: String) -> void:
	stat_name = _name
	stat_name_label.text = _name


func set_stat_point(_points: int) -> void:
	stat_point_label.text = "%s" % _points
