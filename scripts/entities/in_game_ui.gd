## InGameUI
## Manages all user interface elements during gameplay, including the HUD,
## player stats, leveling, stat point allocation, and lootable item tables.
extends Control

# ─── Exported Variables ──────────────────────────────────────────────────────
@export var openTexture: Texture2D
@export var closeTexture: Texture2D

# ─── Public Variables ────────────────────────────────────────────────────────
var lootable_item_slots: Array[LootableItemSlot] = []
var lootable_items_numbers = 20
var selected_lootable_items: Array[LootableItemSlot] = []

var inventory_slots: Array[InventorySlot] = []
var inventory_slots_number = 56

# ─── OnReady Variables ───────────────────────────────────────────────────────
# Hero stats section
@onready var hero_avatar: TextureRect = %HeroAvatar
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var mana_bar: TextureProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
@onready var level_progress_bar: TextureProgressBar = $HeroContainer/Container/LevelProgressBar
@onready var level_label: Label = $HeroContainer/Container/Control/LevelLabel

# Hero panel section
@onready var hud: Panel = $HUD
@onready var tab_container: TabContainer = $HUD/TabContainer
@onready var panel_button: TextureButton = $Control/HeroPanelControl/PanelButton

# Hero Stats Tab
@onready var stats_panel: Panel = $HUD/TabContainer/StatsPanel
@onready var stat_container_scene: PackedScene = preload("res://scenes/ui/stat_container.tscn")
@onready var stats_container: VBoxContainer = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/StatsContainer
@onready var stats_points_label: Label = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/StatsContainer/StatsPointsLabel
@onready var save_stats_button: Button = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/HBoxContainer/SaveStatsButton
@onready var cancel_stats_button: Button = $HUD/TabContainer/StatsPanel/MarginContainer/VBoxContainer/HBoxContainer/CancelStatsButton

# Lootable items section
@onready var lootable_item_slot_scene: PackedScene = preload("res://scenes/ui/lootable_item_slot.tscn")
@onready var lootable_items_container: GridContainer = $Control/LootableItemsTable/MarginContainer/VBoxContainer/ScrollContainer/LootableItemsContainer
@onready var pick_all_dropped_items_button: Button = $Control/LootableItemsTable/MarginContainer/VBoxContainer/HBoxContainer/PickAllDroppedItemsButton
@onready var pick_selected_dropped_items_button: Button = $Control/LootableItemsTable/MarginContainer/VBoxContainer/HBoxContainer/PickSelectedDroppedItemsButton
@onready var cancel_dropped_items_button: Button = $Control/LootableItemsTable/MarginContainer/VBoxContainer/HBoxContainer/CancelDroppedItemsButton
@onready var items_label: Label = $Control/LootableItems/LootableItemsNotiication/ItemsLabel
@onready var lootable_items_table: Panel = $Control/LootableItemsTable

# Inventory items section
@onready var inventory_slot_scene: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")
@onready var inventory_container: GridContainer = $HUD/TabContainer/InventoryPanel/MarginContainer/ScrollContainer/InventoryContainer

# Equipement section
@onready var helmet_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/HelmetSlot
@onready var chest_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/ChestSlot
@onready var weapon_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/WeaponSlot
@onready var boots_s_lot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/BootsSLot
@onready var pet_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/PetSlot
@onready var amulet_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/Panel/HBoxContainer/AmuletSlot
@onready var ring_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/Panel/HBoxContainer/RingSlot
@onready var shield_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/ShieldSlot
@onready var cloak_slot: EquipementSlot = $HUD/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/CloakSlot


# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud.visible = false
	lootable_items_table.visible = false
	
	EventBus.initialize_hero_stats_ui.connect(_initialize_hero_stats)
	EventBus.display_lootable_item_hover_info.connect(_on_display_lootable_item_hover_info)
	EventBus.hide_lootable_item_hover_info.connect(_on_hide_lootable_item_hover_info)
	EventBus.items_added_to_inventory.connect(_on_items_added_to_inventory)
	# EventBus.items_removed_from_inventory.connect(_on_items_removed_from_inventory)
	EventBus.item_equipped.connect(_on_item_equipped)
	
	pick_all_dropped_items_button.pressed.connect(_pick_all_lootable_items)
	pick_selected_dropped_items_button.pressed.connect(_pick_selected_lootable_items)
	cancel_dropped_items_button.pressed.connect(_close_lootable_items_panel)
	
	_initialize_lootable_items_panel()
	_initialize_inventory_tab()

# ─── Public Methods ──────────────────────────────────────────────────────────
## Updates the entire stats UI by reading from PlayerData.
func update_stats() -> void:
	for child in stats_container.get_children():
		if child is StatContainer:
			child.set_stat_point(PlayerData.get_allocated_stat(child.stat_name))
	_set_stats_points_label_text("Stats points: %s" % PlayerData.get_stat_points_available())

## Called to update the hero avatar texture.
func on_hero_avatar_texture(texture: Texture2D) -> void:
	_set_hero_avatar_texture(texture)

## Called to update the HP bar visually.
func on_hp_bar_value(value: float) -> void:
	_set_hp_bar_value(value)
	var text = "%s / %s" % [value, hp_bar.max_value]
	_set_hp_label_text(text)

## Called to update the Mana bar visually.
func on_mana_bar_value(value: float) -> void:
	_set_mana_bar_value(value)
	var text = "%s / %s" % [value, mana_bar.max_value]
	_set_mana_label_text(text)

# ─── Private UI Setters ──────────────────────────────────────────────────────
func _set_hp_max_value(value: float) -> void: hp_bar.max_value = value
func _set_mana_max_value(value: float) -> void: mana_bar.max_value = value
func _set_hero_avatar_texture(texture: Texture2D) -> void: hero_avatar.texture = texture
func _set_hp_bar_value(value: float) -> void: hp_bar.value = value
func _set_hp_label_text(text: String) -> void: hp_label.text = text
func _set_mana_bar_value(value: float) -> void: mana_bar.value = value
func _set_mana_label_text(text: String) -> void: mana_label.text = text
func _set_level_progress_bar_value(value: int) -> void: level_progress_bar.value = value
func _set_level_progress_bar_max_value(value: int) -> void: level_progress_bar.max_value = value
func _set_level_label_text(text: String) -> void: level_label.text = text
func _set_stats_points_label_text(text: String) -> void: stats_points_label.text = text

# ─── Initialization Methods ──────────────────────────────────────────────────
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

func _initialize_inventory_tab() -> void:
	for i in range(inventory_slots_number):
		var inventory_slot_instance: InventorySlot = inventory_slot_scene.instantiate()
		inventory_slot_instance.slot_index = i
		inventory_slots.append(inventory_slot_instance)
		inventory_container.add_child(inventory_slot_instance)

# ─── Logic Methods ───────────────────────────────────────────────────────────
func _pick_all_lootable_items() -> void:
	var slots: Array[Item] = []
	for i in lootable_item_slots:
		if i.item != null:
			slots.append(i.item)
			i.clear_slot()
			items_label.text = str(int(items_label.text) - 1)
	selected_lootable_items.clear()
	EventBus.selected_lootable_items_picked_up.emit(slots)

func _pick_selected_lootable_items() -> void:
	var slots: Array[Item] = []
	var temp_slot = []
	for slot in selected_lootable_items:
		if slot.item != null:
			slots.append(slot.item)
			temp_slot.append(slot)
	
	for slot in temp_slot:
		slot.clear_slot()
		selected_lootable_items.erase(slot)
		items_label.text = str(int(items_label.text) - 1)
	
	EventBus.selected_lootable_items_picked_up.emit(slots)

func _close_lootable_items_panel() -> void:
	__toggle_lootable_items_panel()

func __toggle_panel_button() -> void:
	if panel_button.texture_normal == openTexture:
		panel_button.texture_normal = closeTexture
		return
	panel_button.texture_normal = openTexture

func __toggle_hud_visibility() -> void:
	hud.visible = !hud.visible
	#get_tree().paused = hud.visible

func __toggle_lootable_items_panel() -> void:
	lootable_items_table.visible = !lootable_items_table.visible


# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_display_lootable_item_hover_info(item: Item) -> void:
	for i in lootable_item_slots:
		if i.item == null:
			i.set_item(item)
			items_label.text = str(int(items_label.text) + 1)
			return

func _on_hide_lootable_item_hover_info(item: Item) -> void:
	for i in lootable_item_slots:
		if i.item == item:
			if i in selected_lootable_items:
				selected_lootable_items.erase(i)
			i.clear_slot()
			items_label.text = str(int(items_label.text) - 1)
			return

func _on_lootable_item_slot_clicked(slot_index: int) -> void:
	if lootable_item_slots[slot_index].item != null:
		var selected = lootable_item_slots[slot_index] in selected_lootable_items
		if not selected:
			selected_lootable_items.append(lootable_item_slots[slot_index])
		else:
			selected_lootable_items.erase(lootable_item_slots[slot_index])

func _on_level_up() -> void:
	_set_level_label_text("%s" % [PlayerData.get_player_level()])
	_set_level_progress_bar_max_value(PlayerData.get_total_xp_to_next_level())
	_set_stats_points_label_text("Stats points: %s" % PlayerData.get_stat_points_available())

func _xp_changed(current_xp: int) -> void:
	_set_level_progress_bar_value(current_xp)

func _on_panel_button_pressed() -> void:
	__toggle_panel_button()
	__toggle_hud_visibility()

func _on_toggle_lootable_items_button_pressed() -> void:
	__toggle_lootable_items_panel()

func _on_items_added_to_inventory(slots: Array[Item]) -> void:
	for slot in slots:
		for i in inventory_slots:
			if i.item == null:
				i.set_item(slot)
				break

func _on_item_equipped(item: Equipable) -> void:
	if item is Weapon:
		weapon_slot.set_item(item)
		return
	if item is Armor:
		if item.armor_type == Armor.ArmorType.HELMET:
			helmet_slot.set_item(item)
			return
		if item.armor_type == Armor.ArmorType.CHEST:
			chest_slot.set_item(item)
			return
		if item.armor_type == Armor.ArmorType.BOOTS:
			boots_s_lot.set_item(item)
			return
		# if item.armor_type == Armor.ArmorType.GLOVES:
		# 	gloves_slot.set_item(item)
		# 	return
		if item.armor_type == Armor.ArmorType.RING:
			ring_slot.set_item(item)
			return
		if item.armor_type == Armor.ArmorType.AMULET:
			amulet_slot.set_item(item)
			return
		if item.armor_type == Armor.ArmorType.CLOAK:
			cloak_slot.set_item(item)
			return
		if item.armor_type == Armor.ArmorType.SHIELD:
			shield_slot.set_item(item)
			return