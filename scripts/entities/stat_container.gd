## StatContainer
## A UI component representing a single character stat, allowing the player
## to add or subtract points from it.
extends HBoxContainer
class_name StatContainer

# ─── Public Variables ────────────────────────────────────────────────────────
## The name of the stat this container represents (e.g., "STR", "INT").
var stat_name: String = ""

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var stat_name_label: Label = $StatNameLabel
@onready var stat_point_label: Label = $StatPointLabel
@onready var add_stat_point_button: Button = $AddStatPointButton
@onready var sub_stat_point_button: Button = $SubStatPointButton

# ─── Public Methods ──────────────────────────────────────────────────────────
## Sets the name of the stat and updates the label.
func set_stat_name(_name: String) -> void:
	stat_name = _name
	stat_name_label.text = _name

## Sets the displayed points for this stat.
func set_stat_point(_points: int) -> void:
	stat_point_label.text = "%s" % _points
