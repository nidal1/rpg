extends Panel
class_name LootableItemSlot

enum LootableItemSlotState {
	normal,
	hover,
	pressed
}

@onready var lootable_item_image: TextureRect = $CenterContainer/LootableItemImage
@onready var lootable_item_button: TextureButton = $LootableItemButton

var slot_index: int
var item: Item = null

var style_box = StyleBoxFlat.new()

var current_slot_state: LootableItemSlotState = LootableItemSlotState.normal

const slot_normal_stat_border_color: Color = Color("#1a1a1a")
const slot_hover_stat_border_color: Color = Color("#525252")
const slot_pressed_stat_border_color: Color = Color("#797979")

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


func set_item(item_resource: Item) -> void:
	if not item_resource:
		return
	item = item_resource
	lootable_item_image.texture = item.icon

func clear_slot() -> void:
	lootable_item_image.texture = null
	item = null
	current_slot_state = LootableItemSlotState.normal
	style_box.border_color = slot_normal_stat_border_color
	add_theme_stylebox_override("panel", style_box)
