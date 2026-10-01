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
var inventory_slots_number = 35

var item_table_details_visible: bool = false
var item_table_details_instance: EquipableTableDetails

var item_card_details_visible: bool = false
var item_card_details_instance: ItemCardDetails

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
@onready var tab_container: TabContainer = $HUD/TabsPanel/TabContainer
@onready var panel_button: TextureButton = $Control/HeroPanelControl/PanelButton

# Hero Stats Tab
@onready var stats_panel: Panel = $HUD/TabsPanel/TabContainer/StatsPanel
@onready var stat_container_scene: PackedScene = preload("res://scenes/ui/stat_container.tscn")
@onready var stats_container: VBoxContainer = $HUD/TabsPanel/TabContainer/StatsPanel/MarginContainer/VBoxContainer/StatsContainer
@onready var stats_points_label: Label = $HUD/TabsPanel/TabContainer/StatsPanel/MarginContainer/VBoxContainer/StatsContainer/StatsPointsLabel
@onready var save_stats_button: Button = $HUD/TabsPanel/TabContainer/StatsPanel/MarginContainer/VBoxContainer/HBoxContainer/SaveStatsButton
@onready var cancel_stats_button: Button = $HUD/TabsPanel/TabContainer/StatsPanel/MarginContainer/VBoxContainer/HBoxContainer/CancelStatsButton

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
@onready var inventory_container: GridContainer = $HUD/TabsPanel/TabContainer/InventoryPanel/MarginContainer/VBoxContainer/ScrollContainer/InventoryContainer
@onready var available_gold_label: Label = $HUD/TabsPanel/TabContainer/InventoryPanel/MarginContainer/VBoxContainer/HBoxContainer/AvailableGoldLabel

# Equipement section
@onready var helmet_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/HelmetSlot
@onready var chest_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/ChestSlot
@onready var weapon_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/WeaponSlot
@onready var boots_s_lot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementLeftContainerSlots/BootsSLot
@onready var pet_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/PetSlot
@onready var amulet_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/Panel/HBoxContainer/AmuletSlot
@onready var ring_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/Panel/HBoxContainer/RingSlot
@onready var shield_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/ShieldSlot
@onready var cloak_slot: EquipementSlot = $HUD/TabsPanel/TabContainer/EquipementsPanel/MarginContainer/HBoxContainer/EquipementRightContainerSlots/CloakSlot

# Potions section
@onready var health_potion_slot: PotionSlot = $PotionsContainer/MarginContainer/HBoxContainer/HealthPotionSlot
@onready var mana_potion_slot: PotionSlot = $PotionsContainer/MarginContainer/HBoxContainer/ManaPotionSlot

# Merchant shop section
@onready var merchant_panel: Panel = $HUD/MerchantPanel
@onready var merchant_container: GridContainer = $HUD/MerchantPanel/VBoxContainer/MarginContainer/ScrollContainer/MerchantContainer
@onready var merchant_store_slot_scene: PackedScene = preload("res://scenes/ui/merchant_store_slot.tscn")

# Global Popups
@onready var popups: Node2D = $Popups
@export var merchant_buy_item_modal_scene: PackedScene
@export var armor_table_details_scene: PackedScene
@export var weapon_table_details_scene: PackedScene
@export var item_card_details_scene: PackedScene

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud.visible = false
	lootable_items_table.visible = false
	merchant_panel.visible = false
	
	EventBus.toggle_hud_visiblity.connect(_on_toggle_hud_visibility)
	EventBus.toggle_merchant_store_panel_visibility.connect(_on_toggle_merchant_store_panel_visibility)
	EventBus.display_lootable_item_hover_info.connect(_on_display_lootable_item_hover_info)
	EventBus.hide_lootable_item_hover_info.connect(_on_hide_lootable_item_hover_info)
	EventBus.items_added_to_inventory.connect(_on_items_added_to_inventory)
	EventBus.items_removed_from_inventory.connect(_on_items_removed_from_inventory)
	EventBus.item_equipped.connect(_on_item_equipped)

	EventBus.show_item_table_details.connect(_on_show_item_table_details)
	EventBus.hide_item_table_details.connect(_on_hide_item_table_details)

	EventBus.potions_added_to_list.connect(_on_potion_slot_potions_added_to_list)
	EventBus.udpate_available_gold.connect(_on_udpate_available_gold)
	pick_all_dropped_items_button.pressed.connect(_pick_all_lootable_items)
	pick_selected_dropped_items_button.pressed.connect(_pick_selected_lootable_items)
	cancel_dropped_items_button.pressed.connect(_close_lootable_items_panel)
	
	_initialize_hero_stats()
	_initialize_lootable_items_panel()
	_initialize_inventory_tab()

# StatsUI component
var stats_ui: StatsUI = StatsUI.new()


# ─── Initialization Methods ──────────────────────────────────────────────────
func _initialize_hero_stats() -> void:
	if not is_ancestor_of(stats_ui):
		add_child(stats_ui)
	stats_ui.setup_ui_references(
		hero_avatar, hp_bar, hp_label, mana_bar, mana_label,
		level_progress_bar, level_label, stats_container,
		stats_points_label, save_stats_button, cancel_stats_button
	)

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
	var slots: Array[DataItem] = []
	for i in lootable_item_slots:
		if i.item != null:
			slots.append(i.item)
			i.clear_slot()
			items_label.text = str(int(items_label.text) - 1)
	selected_lootable_items.clear()
	EventBus.selected_lootable_items_picked_up.emit(slots)

func _pick_selected_lootable_items() -> void:
	var slots: Array[DataItem] = []
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


func __toggle_lootable_items_panel() -> void:
	lootable_items_table.visible = !lootable_items_table.visible

func __set_hero_active_tab(index: int):
	tab_container.current_tab = index

func __update_merchant_store_items(items: Array[DataItem]):
	for child in merchant_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	for item in items:
		var item_slot: MerchantStoreSlot = merchant_store_slot_scene.instantiate()
		merchant_container.add_child(item_slot)
		item_slot.set_item(item)
		item_slot.mouse_enter.connect(_on_show_item_card_details)
		item_slot.mouse_exit.connect(_on_hide_item_card_details)
		item_slot.mouse_clicked.connect(_on_merchant_store_item_clicked)

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_show_item_card_details(item: DataItem):
	if item_card_details_visible or item_card_details_instance:
		return
		
	item_card_details_instance = item_card_details_scene.instantiate()
	item_card_details_instance.data_item = item
	popups.add_child(item_card_details_instance)
	var mouse_pos = get_global_mouse_position()
	item_card_details_instance.position = mouse_pos
	item_card_details_instance.show()

func _on_hide_item_card_details() -> void:
	if item_card_details_instance:
		item_card_details_instance.hide()
		item_card_details_instance.queue_free()
		item_card_details_instance = null

func _on_merchant_store_item_clicked(data_item: DataItem):
	var modal: MerchantBuyItemModal = merchant_buy_item_modal_scene.instantiate()
	popups.add_child(modal)
	var centerize = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	modal.position = centerize
	modal.buy_button_clicked.connect(func(value: float): EventBus.buy_item.emit(value, data_item))

func _on_display_lootable_item_hover_info(item: DataItem) -> void:
	for i in lootable_item_slots:
		if i.item == null:
			i.set_item(item)
			items_label.text = str(int(items_label.text) + 1)
			return

func _on_toggle_hud_visibility() -> void:
	hud.visible = !hud.visible

func _on_toggle_merchant_store_panel_visibility(items: Array[DataItem]) -> void:
	var _visible = merchant_panel.visible
	if not _visible:
		__set_hero_active_tab(1)
		__update_merchant_store_items(items)
		merchant_panel.visible = !_visible
	else:
		for child in merchant_container.get_children():
			if is_instance_valid(child):
				child.queue_free()
		merchant_panel.visible = !_visible

func _on_hide_lootable_item_hover_info(item: DataItem) -> void:
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

func _on_panel_button_pressed() -> void:
	__toggle_panel_button()
	EventBus.toggle_hud_visiblity.emit()

func _on_toggle_lootable_items_button_pressed() -> void:
	__toggle_lootable_items_panel()

func _on_items_removed_from_inventory(slots: Array[DataItem]) -> void:
	for slot in slots:
		for i in inventory_slots:
			if i.item == slot:
				i.clear_slot()
				break

func _on_items_added_to_inventory(slots: Array[DataItem]) -> void:
	for slot in slots:
		for i in inventory_slots:
			if i.item == null:
				i.set_item(slot)
				break
## TODO: use enum instead of hard coded names
func _on_item_equipped(inventory_slot: InventorySlot) -> void:
	var item: EquipableItem = inventory_slot.get_item() as EquipableItem
	if item == null:
		return
	
	var eq_type = item.equipment_type.to_upper()
	if "SWORD" in eq_type or "AXE" in eq_type or "MACE" in eq_type or "BOW" in eq_type or "CROSSBOW" in eq_type or "DAGGER" in eq_type or "WEAPON" in eq_type:
		weapon_slot.set_item(item)
		inventory_slot.clear_slot()
		return
	if eq_type == "HELMET" or eq_type == "HEAD":
		helmet_slot.set_item(item)
		inventory_slot.clear_slot()
		return
	if eq_type == "CHEST" or eq_type == "ARMOR":
		chest_slot.set_item(item)
		inventory_slot.clear_slot()
		return
	if eq_type == "BOOTS" or eq_type == "FEET":
		boots_s_lot.set_item(item)
		inventory_slot.clear_slot()
		return
	if eq_type == "RING":
		ring_slot.set_item(item)
		inventory_slot.clear_slot()
		return
	if eq_type == "AMULET" or eq_type == "NECKLACE":
		amulet_slot.set_item(item)
		inventory_slot.clear_slot()
		return
	if eq_type == "CLOAK":
		cloak_slot.set_item(item)
		inventory_slot.clear_slot()
		return
	if eq_type == "SHIELD":
		shield_slot.set_item(item)
		inventory_slot.clear_slot()
		return

func _on_show_item_table_details(item: DataItem) -> void:
	if item_table_details_instance or item_table_details_visible:
		return
	if item is EquipableItem:
		var eq = item as EquipableItem
		if eq.is_armor():
			item_table_details_instance = armor_table_details_scene.instantiate()
		else:
			item_table_details_instance = weapon_table_details_scene.instantiate()
		popups.add_child(item_table_details_instance)
		item_table_details_instance.set_equipable_item(eq)
		var mouse_pos = get_global_mouse_position()
		var item_table_details_size = item_table_details_instance.get_size()
		item_table_details_instance.position = mouse_pos
		if mouse_pos.x + item_table_details_size.x > get_viewport().size.x:
			item_table_details_instance.position -= mouse_pos - Vector2(item_table_details_size.x, 0)
		if mouse_pos.y + item_table_details_size.y > get_viewport().size.y:
			item_table_details_instance.position -= Vector2(0, mouse_pos.y + item_table_details_size.y - get_viewport().size.y)
		item_table_details_instance.show()

## TODO: use enum instead of hard coded names
func _on_potion_slot_potions_added_to_list(potion: ConsumableItem) -> void:
	if potion:
		if potion.potion_type.to_upper() == "HEALTH":
			health_potion_slot.equip(potion)
		elif potion.potion_type.to_upper() == "MANA":
			mana_potion_slot.equip(potion)

func _on_hide_item_table_details() -> void:
	if item_table_details_instance:
		item_table_details_instance.hide()
		item_table_details_instance.queue_free()
		item_table_details_instance = null

func _on_health_potion_texture_button_pressed() -> void:
	print("health potion pressed")

func _on_mana_potion_texture_button_pressed() -> void:
	print("mana potion pressed")

func _on_udpate_available_gold(_value: int):
	available_gold_label.text = str("Available Gold: ",_value)
