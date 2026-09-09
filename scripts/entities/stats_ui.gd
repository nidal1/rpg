extends Control
class_name StatsUI

# References to UI elements (configured via setup or parent UI)
var hero_avatar: TextureRect
var hp_bar: TextureProgressBar
var hp_label: Label
var mana_bar: TextureProgressBar
var mana_label: Label
var level_progress_bar: TextureProgressBar
var level_label: Label

var stats_container: VBoxContainer
var stats_points_label: Label
var save_stats_button: Button
var cancel_stats_button: Button

var stat_container_scene: PackedScene = preload("res://scenes/ui/stat_container.tscn")

var hp_tween: Tween
var mana_tween: Tween
var xp_tween: Tween

func setup_ui_references(
	p_hero_avatar: TextureRect,
	p_hp_bar: TextureProgressBar,
	p_hp_label: Label,
	p_mana_bar: TextureProgressBar,
	p_mana_label: Label,
	p_level_progress_bar: TextureProgressBar,
	p_level_label: Label,
	p_stats_container: VBoxContainer,
	p_stats_points_label: Label,
	p_save_stats_button: Button,
	p_cancel_stats_button: Button
) -> void:
	hero_avatar = p_hero_avatar
	hp_bar = p_hp_bar
	hp_label = p_hp_label
	mana_bar = p_mana_bar
	mana_label = p_mana_label
	level_progress_bar = p_level_progress_bar
	level_label = p_level_label
	stats_container = p_stats_container
	stats_points_label = p_stats_points_label
	save_stats_button = p_save_stats_button
	cancel_stats_button = p_cancel_stats_button

	EventBus.stats_updated.connect(update_stats)
	EventBus.update_hero_avatar_texture.connect(on_hero_avatar_texture)
	EventBus.hero_hp_changed.connect(_on_hero_hp_changed)
	EventBus.hero_mp_changed.connect(_on_hero_mp_changed)
	EventBus.hero_xp_changed.connect(_on_hero_xp_changed)
	EventBus.stat_points_available_changed.connect(_on_stat_points_available_changed)
	EventBus.level_up.connect(_on_level_up)

	set_hero_avatar_texture(hero_avatar.texture)
	var hp = int(round(StatsData.get_stats().get_max_hp()))
	var mana = int(round(StatsData.get_stats().get_max_mp()))
	set_hp_max_value(hp)
	set_hp_bar_value(hp)
	set_mana_max_value(mana)
	set_mana_bar_value(mana)
	set_hp_label_text("%s / %s" % [hp, hp])
	set_mana_label_text("%s / %s" % [mana, mana])
	set_level_label_text("%s" % [PlayerData.get_player_level()])
	set_level_progress_bar_max_value(PlayerData.get_total_xp_to_next_level())
	set_level_progress_bar_value(PlayerData.get_current_xp())

	initialize_stats_tab()
	
	if save_stats_button:
		save_stats_button.pressed.connect(func(): EventBus.save_stats_points.emit())
	if cancel_stats_button:
		cancel_stats_button.pressed.connect(func(): EventBus.cancel_stats_points.emit())

func set_hp_max_value(value: float) -> void: hp_bar.max_value = value
func set_mana_max_value(value: float) -> void: mana_bar.max_value = value
func set_hero_avatar_texture(texture: Texture2D) -> void: hero_avatar.texture = texture
func set_hp_bar_value(value: float) -> void: hp_bar.value = value
func set_hp_label_text(text: String) -> void: hp_label.text = text
func set_mana_bar_value(value: float) -> void: mana_bar.value = value
func set_mana_label_text(text: String) -> void: mana_label.text = text
func set_level_progress_bar_value(value: int) -> void: level_progress_bar.value = value
func set_level_progress_bar_max_value(value: int) -> void: level_progress_bar.max_value = value
func set_level_label_text(text: String) -> void: level_label.text = text
func set_stats_points_label_text(text: String) -> void: stats_points_label.text = text


func initialize_stats_tab() -> void:
	if not stats_container: return
	for child in stats_container.get_children():
		if child is StatContainer:
			child.queue_free()

	for stat_name in StatsData.STAT_NAMES_NO_FLT:
		var stat_container_instance: StatContainer = stat_container_scene.instantiate()
		stats_container.add_child(stat_container_instance)
		stat_container_instance.set_stat_name(stat_name)
		var allocate_point = StatsData.get_allocated_stat(stat_name)
		var _temp_alloc = StatsData.get_temp_allocated_stat(stat_name)
		var total = StatsData.get_total(stat_name)
		stat_container_instance.set_stat_point(allocate_point, total)
		stat_container_instance.add_stat_point_button.pressed.connect(func(): EventBus.stat_allocated.emit(stat_name))
		stat_container_instance.sub_stat_point_button.pressed.connect(func(): EventBus.stat_deallocated.emit(stat_name))

	update_stats_panel()

## Updates the entire stats UI (both Stats Panel and Hero HUD).
func update_stats(stats_data: StatsData = null) -> void:
	update_all_stats_ui(stats_data)

func update_stats_panel() -> void:
	if not stats_container: return
	var available_points = StatsData.get_stat_points_available()
	for child in stats_container.get_children():
		if child is StatContainer:
			var alloc = StatsData.get_allocated_stat(child.stat_name)
			var temp_alloc = StatsData.get_temp_allocated_stat(child.stat_name)
			var total = StatsData.get_total(child.stat_name)
			child.set_stat_point(alloc, total)
			child.set_button_states(available_points > 0, alloc > temp_alloc)
	if stats_points_label:
		stats_points_label.text = "Stats points: %s" % available_points

## Master update method dispatched whenever stats change.
## Updates both the Stats Panel tab and the Hero HUD.
func update_all_stats_ui(stats_data: StatsData = null) -> void:
	update_stats_panel()
	var stats: CharacterStats = stats_data.get_stats() if stats_data else (StatsData.get_stats() if StatsData else null)
	if stats:
		update_hero_hud(stats)

func update_hero_hud(stats: CharacterStats = null) -> void:
	if not stats and StatsData:
		stats = StatsData.get_stats()
	if not stats: return
	var hp = int(round(stats.get_max_hp()))
	var mana = int(round(stats.get_max_mp()))
	if hp_bar: hp_bar.max_value = hp
	if mana_bar: mana_bar.max_value = mana
	var current_hp = hp_bar.value if hp_bar else 0.0
	var current_mana = mana_bar.value if mana_bar else 0.0
	if hp_label: hp_label.text = "%d / %d" % [int(round(current_hp)), hp]
	if mana_label: mana_label.text = "%d / %d" % [int(round(current_mana)), mana]

func update_hp_bar_smooth(value: float) -> void:
	if not hp_bar: return
	if hp_tween and hp_tween.is_running():
		hp_tween.kill()
	hp_tween = create_tween()
	hp_tween.tween_property(hp_bar, "value", value, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if hp_label:
		hp_label.text = "%d / %d" % [int(round(value)), int(round(hp_bar.max_value))]

func update_mana_bar_smooth(value: float) -> void:
	if not mana_bar: return
	if mana_tween and mana_tween.is_running():
		mana_tween.kill()
	mana_tween = create_tween()
	mana_tween.tween_property(mana_bar, "value", value, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if mana_label:
		mana_label.text = "%d / %d" % [int(round(value)), int(round(mana_bar.max_value))]

func update_xp_bar_smooth(current_xp: int, total_xp: int) -> void:
	if level_progress_bar:
		level_progress_bar.max_value = total_xp
		if xp_tween and xp_tween.is_running():
			xp_tween.kill()
		xp_tween = create_tween()
		xp_tween.tween_property(level_progress_bar, "value", current_xp, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Called to update the hero avatar texture.
func on_hero_avatar_texture(texture: Texture2D) -> void:
	set_hero_avatar_texture(texture)

# Called to update the HP bar visually with smooth tweening.
func on_hp_bar_value(value: float) -> void:
	update_hp_bar_smooth(value)

# Called to update the Mana bar visually with smooth tweening.
func on_mana_bar_value(value: float) -> void:
	update_mana_bar_smooth(value)

func _on_hero_hp_changed(current_hp: float, max_hp: float) -> void:
	set_hp_max_value(max_hp)
	on_hp_bar_value(current_hp)

func _on_hero_mp_changed(current_mp: float, max_mp: float) -> void:
	set_mana_max_value(max_mp)
	on_mana_bar_value(current_mp)

func _on_hero_xp_changed(current_xp: int, total_xp: int) -> void:
	update_xp_bar_smooth(current_xp, total_xp)

func _on_stat_points_available_changed(_points: int) -> void:
	update_stats_panel()

func _on_level_up() -> void:
	set_level_label_text("%s" % [PlayerData.get_player_level()])
	set_level_progress_bar_max_value(PlayerData.get_total_xp_to_next_level())
	set_stats_points_label_text("Stats points: %s" % StatsData.get_stat_points_available())

func _xp_changed(current_xp: int) -> void:
	set_level_progress_bar_value(current_xp)
