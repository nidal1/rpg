extends Control

# Hero stats section -------------------------------------------------
@onready var hero_avatar: TextureRect = %HeroAvatar
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var mana_bar: TextureProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
@onready var level_progress_bar: TextureProgressBar = $HeroContainer/Container/LevelProgressBar
@onready var level_label: Label = $HeroContainer/Container/Control/LevelLabel

# Hero panel section -------------------------------------------------
@onready var hud: Panel = $HUD
@onready var tab_container: TabContainer = $HUD/TabContainer
@export var openTexture: Texture2D
@export var closeTexture: Texture2D
@onready var panel_button: TextureButton = $Control/HeroPanelControl/PanelButton

# Hero Stats Tab -------------------------------------------------
@onready var stats_panel: Panel = $HUD/TabContainer/StatsPanel
@onready var stat_container_scene: PackedScene = preload("res://scenes/ui/stat_container.tscn")
@onready var stats_container: VBoxContainer = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/StatsContainer
@onready var stats_points_label: Label = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/StatsContainer/StatsPointsLabel
@onready var save_stats_button: Button = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/HBoxContainer/SaveStatsButton
@onready var cancel_stats_button: Button = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/HBoxContainer/CancelStatsButton

# Lootable items section -------------------------------------------------
@onready var lootable_item_slot_scene: PackedScene = preload("res://scenes/ui/lootable_item_slot.tscn")
@onready var lootable_items_container: GridContainer = $Control/LootableItemsTable/MarginContainer/VBoxContainer/ScrollContainer/LootableItemsContainer
@onready var pick_all_dropped_items_button: Button = $Control/LootableItemsTable/MarginContainer/VBoxContainer/HBoxContainer/PickAllDroppedItemsButton
@onready var pick_selected_dropped_items_button: Button = $Control/LootableItemsTable/MarginContainer/VBoxContainer/HBoxContainer/PickSelectedDroppedItemsButton
@onready var cancel_dropped_items_button: Button = $Control/LootableItemsTable/MarginContainer/VBoxContainer/HBoxContainer/CancelDroppedItemsButton

var lootable_item_slots: Array[LootableItemSlot] = []
var lootable_items_numbers = 20
var selected_lootable_items: Array[LootableItemSlot] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud.visible = false
	EventBus.initialize_hero_stats_ui.connect(_initialize_hero_stats)
	EventBus.display_lootable_item_hover_info.connect(_on_display_lootable_item_hover_info)
	EventBus.hide_lootable_item_hover_info.connect(_on_hide_lootable_item_hover_info)
	# pick_all_dropped_items_button.pressed.connect(_pick_all_dropped_items)
	pick_selected_dropped_items_button.pressed.connect(_pick_selected_lootable_items)
	# cancel_dropped_items_button.pressed.connect(_cancel_dropped_items)
	_initialize_lootable_items_panel()

	
func _initialize_hero_stats(cls: CharacterClass) -> void:
	_initialize_stats_tab()
	_initialize_hero(cls)
	

	EventBus.update_hero_avatar_texture.connect(on_hero_avatar_texture)
	EventBus.update_hp_bar_value.connect(on_hp_bar_value)
	EventBus.update_mana_bar_value.connect(on_mana_bar_value)

	EventBus.level_up.connect(_on_level_up)
	EventBus.xp_changed.connect(_xp_changed)


func _initialize_stats_tab() -> void:
	EventBus.stats_updated.connect(update_stats)
	save_stats_button.pressed.connect(EventBus.save_stats_points.emit)
	cancel_stats_button.pressed.connect(EventBus.cancel_stats_points.emit)
	stats_points_label.text = "Stats points: %s" % PlayerData.get_stat_points_available()
	
	for child in stats_container.get_children():
		if child is StatContainer:
			child.queue_free()


	for stat_name in PlayerData.STAT_NAMES:
		var stat_container_instance: StatContainer = stat_container_scene.instantiate()
		
		stats_container.add_child(stat_container_instance)
		
		stat_container_instance.set_stat_name(stat_name)
		
		var allocate_point = PlayerData.get_allocated_stat(stat_name)
		stat_container_instance.set_stat_point(allocate_point)

		stat_container_instance.add_stat_point_button.pressed.connect(func(): EventBus.stat_allocated.emit(stat_name))
		stat_container_instance.sub_stat_point_button.pressed.connect(func(): EventBus.stat_deallocated.emit(stat_name))

func _initialize_hero(cls: CharacterClass) -> void:
	_set_hero_avatar_texture(cls.avatar_texture)
	_set_hp_max_value(cls.max_health)
	_set_hp_bar_value(cls.max_health)
	_set_mana_max_value(cls.max_mana)
	_set_mana_bar_value(cls.max_mana)
	_set_hp_label_text("%s / %s" % [cls.max_health, cls.max_health])
	_set_mana_label_text("%s / %s" % [cls.max_mana, cls.max_mana])

	_set_level_label_text("%s" % [PlayerData.get_player_level()])
	_set_level_progress_bar_max_value(PlayerData.get_total_xp_to_next_level())
	_set_level_progress_bar_value(PlayerData.get_current_xp())

func _initialize_lootable_items_panel() -> void:
	for i in range(lootable_items_numbers):
		var lootable_item_slot_instance: LootableItemSlot = lootable_item_slot_scene.instantiate()
		lootable_item_slot_instance.slot_index = i
		lootable_item_slots.append(lootable_item_slot_instance)
		lootable_items_container.add_child(lootable_item_slot_instance)
		lootable_item_slot_instance.lootable_item_button.pressed.connect(func(): _on_lootable_item_slot_clicked(i))

func _on_display_lootable_item_hover_info(item: Item) -> void:
	print("displaying item hover info")
	for i in lootable_item_slots:
		if i.item == null:
			print("found empty slot - slot %s", i.slot_index)
			i.set_item(item)
			return

func _on_hide_lootable_item_hover_info(item: Item) -> void:
	print("hiding item hover info")
	for i in lootable_item_slots:
		if i.item == item:
			if i in selected_lootable_items:
				selected_lootable_items.erase(i)
			i.clear_slot()
			return
	

# Select and deselect lootable item slots
func _on_lootable_item_slot_clicked(slot_index: int) -> void:
	if lootable_item_slots[slot_index].item != null:
		var selected = lootable_item_slots[slot_index] in selected_lootable_items
		if not selected:
			selected_lootable_items.append(lootable_item_slots[slot_index])
		else:
			selected_lootable_items.erase(lootable_item_slots[slot_index])

func _pick_selected_lootable_items():
	var slots: Array[Item] = []
	var temp_slot = []
	for slot in selected_lootable_items:
		if slot.item != null:
			slots.append(slot.item)
			temp_slot.append(slot)
	
	for slot in temp_slot:
		slot.clear_slot()
		selected_lootable_items.erase(slot)
	
	EventBus.selected_lootable_items_picked_up.emit(slots)


func _on_level_up() -> void:
	_set_level_label_text("%s" % [PlayerData.get_player_level()])
	_set_level_progress_bar_max_value(PlayerData.get_total_xp_to_next_level())
	_set_stats_points_label_text("Stats points: %s" % PlayerData.get_stat_points_available())


func _xp_changed(current_xp: int) -> void:
	_set_level_progress_bar_value(current_xp)


func on_hero_avatar_texture(texture: Texture2D):
	_set_hero_avatar_texture(texture)


func on_hp_bar_value(value: float):
	_set_hp_bar_value(value)
	var text = "%s / %s" % [value, hp_bar.max_value]
	_set_hp_label_text(text)


func on_mana_bar_value(value: float):
	_set_mana_bar_value(value)
	var text = "%s / %s" % [value, mana_bar.max_value]
	_set_mana_label_text(text)

func _set_hp_max_value(value: float): hp_bar.max_value = value
func _set_mana_max_value(value: float): mana_bar.max_value = value

func _set_hero_avatar_texture(texture: Texture2D): hero_avatar.texture = texture


func _set_hp_bar_value(value: float): hp_bar.value = value


func _set_hp_label_text(text: String): hp_label.text = text


func _set_mana_bar_value(value: float): mana_bar.value = value


func _set_mana_label_text(text: String): mana_label.text = text

func _set_level_progress_bar_value(value: int): level_progress_bar.value = value

func _set_level_progress_bar_max_value(value: int): level_progress_bar.max_value = value

func _set_level_label_text(text: String): level_label.text = text

func _set_stats_points_label_text(text: String): stats_points_label.text = text

func update_stats() -> void:
	for child in stats_container.get_children():
		if child is StatContainer:
			child.set_stat_point(PlayerData.get_allocated_stat(child.stat_name))
	_set_stats_points_label_text("Stats points: %s" % PlayerData.get_stat_points_available())
	
	
func __toggle_panel_button() -> void:
	if panel_button.texture_normal == openTexture:
		panel_button.texture_normal = closeTexture
		return
	panel_button.texture_normal = openTexture

func __toggle_hud_visibility() -> void:
	hud.visible = !hud.visible
	get_tree().paused = hud.visible


func _on_panel_button_pressed() -> void:
	__toggle_panel_button()

	__toggle_hud_visibility()


func _on_texture_button_pressed() -> void:
	print("pressed")
