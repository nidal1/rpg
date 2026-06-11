extends Panel
class_name InventorySlot

var slot_index: int
var item: Item

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var context_menu: PopupMenu = $ContextMenu
@onready var inventory_slot_icon: TextureRect = $CenterContainer/InventorySlotIcon

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	context_menu.add_item("Equip", 0)
	context_menu.add_item("Use", 1)
	context_menu.add_separator()
	context_menu.add_item("Drop", 2)
	context_menu.id_pressed.connect(_on_context_menu_item_pressed)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not item:
			return
		if item is not Equipable:
			context_menu.set_item_hidden(0, true)
		context_menu.popup()
		# position = mouse position
		context_menu.position = get_screen_position() + event.position

func _on_context_menu_item_pressed(id: int) -> void:
	match id:
		0: _equip()
		1: _use()
		2: _drop()
		
	
func _equip() -> void:
	EventBus.item_equipped.emit(item)
	clear_slot()

func _use() -> void:
	print("use item")

func _drop() -> void:
	EventBus.item_dropped_from_inventory.emit(item)
	clear_slot()


func _on_inventory_slot_button_pressed() -> void:
	print("pressed")

func clear_slot() -> void:
	item = null
	inventory_slot_icon.texture = null

func set_item(new_item: Item) -> void:
	item = new_item
	inventory_slot_icon.texture = item.icon
