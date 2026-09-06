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

## Sets the displayed points for this stat, optionally showing total value (base + bonus).
func set_stat_point(_points: int, total_value: int = -1) -> void:
	if total_value >= 0:
		stat_point_label.text = "%d [Total: %d]" % [_points, total_value]
	else:
		stat_point_label.text = "%d" % _points

## Updates the interactive button states based on point allocation availability.
func set_button_states(can_add: bool, can_sub: bool) -> void:
	if add_stat_point_button:
		add_stat_point_button.disabled = not can_add
	if sub_stat_point_button:
		sub_stat_point_button.disabled = not can_sub
