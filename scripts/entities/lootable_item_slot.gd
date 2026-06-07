## LootableItemSlot
## A UI component representing a single item slot in the lootable items table.
## Handles selection state and interactions for picking up nearby items.
extends Panel
class_name LootableItemSlot

# ─── Enums ───────────────────────────────────────────────────────────────────
enum LootableItemSlotState {
	normal,
	hover,
	pressed
}

# ─── Constants ───────────────────────────────────────────────────────────────
const slot_normal_stat_border_color: Color = Color("#1a1a1a")
const slot_hover_stat_border_color: Color = Color("#525252")
const slot_pressed_stat_border_color: Color = Color("#797979")

# ─── Public Variables ────────────────────────────────────────────────────────
## The index of this slot in the UI container.
var slot_index: int
## The item resource currently displayed in this slot.
var item: Item = null
## The visual style override for the panel border.
var style_box: StyleBoxFlat = StyleBoxFlat.new()
## The current interaction state of this slot.
var current_slot_state: LootableItemSlotState = LootableItemSlotState.normal

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var lootable_item_image: TextureRect = $CenterContainer/LootableItemImage
@onready var lootable_item_button: TextureButton = $LootableItemButton

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	style_box.border_color = slot_normal_stat_border_color
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.corner_radius_top_left = 3
	style_box.corner_radius_top_right = 3
	style_box.corner_radius_bottom_left = 3
	style_box.corner_radius_bottom_right = 3
	style_box.bg_color = Color("#191919")
	style_box.draw_center = true
	add_theme_stylebox_override("panel", style_box)

	lootable_item_button.mouse_entered.connect(func(): _on_lootable_item_button_mouse_entered())
	lootable_item_button.mouse_exited.connect(func(): _on_lootable_item_button_mouse_exited())
	lootable_item_button.pressed.connect(func(): _on_lootable_item_button_mouse_pressed())

# ─── Public Methods ──────────────────────────────────────────────────────────
## Sets the item to be displayed in this slot.
func set_item(item_resource: Item) -> void:
	if not item_resource:
		return
	item = item_resource
	lootable_item_image.texture = item.icon

## Clears the slot, removing its item and resetting its state.
func clear_slot() -> void:
	lootable_item_image.texture = null
	item = null
	current_slot_state = LootableItemSlotState.normal
	style_box.border_color = slot_normal_stat_border_color
	add_theme_stylebox_override("panel", style_box)

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_lootable_item_button_mouse_entered() -> void:
	if current_slot_state == LootableItemSlotState.pressed:
		return
	current_slot_state = LootableItemSlotState.hover
	style_box.border_color = slot_hover_stat_border_color
	add_theme_stylebox_override("panel", style_box)

func _on_lootable_item_button_mouse_exited() -> void:
	if current_slot_state == LootableItemSlotState.pressed:
		return
	current_slot_state = LootableItemSlotState.normal
	style_box.border_color = slot_normal_stat_border_color
	add_theme_stylebox_override("panel", style_box)

func _on_lootable_item_button_mouse_pressed() -> void:
	if current_slot_state != LootableItemSlotState.pressed and item != null:
		current_slot_state = LootableItemSlotState.pressed
		style_box.border_color = slot_pressed_stat_border_color
		add_theme_stylebox_override("panel", style_box)
	else:
		current_slot_state = LootableItemSlotState.normal
		style_box.border_color = slot_normal_stat_border_color
		add_theme_stylebox_override("panel", style_box)
