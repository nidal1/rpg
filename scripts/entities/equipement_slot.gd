extends Panel
class_name EquipementSlot

@export var placeholder_image: Texture2D
@export var slot_key: String = ""

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var context_menu: PopupMenu = $ContextMenu
@onready var placeholder_equipement_image: TextureRect = $CenterContainer/PlaceholderEquipementImage
@onready var equipement_image: TextureRect = $CenterContainer/EquipementImage

var item: Equipable = null

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	if placeholder_image:
		placeholder_equipement_image.texture = placeholder_image

	context_menu.add_item("Unequip", 0)
	context_menu.id_pressed.connect(_on_context_menu_item_pressed)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not item:
			return
		context_menu.popup()
		# position = mouse position
		context_menu.position = get_screen_position() + event.position

func set_item(new_item: Equipable) -> void:
	item = new_item
	update_texture()

func clear_slot() -> void:
	item = null
	update_texture()

func update_texture() -> void:
	if item == null:
		equipement_image.texture = null
		placeholder_equipement_image.visible = true
	else:
		equipement_image.texture = item.icon
		placeholder_equipement_image.visible = false

func _on_context_menu_item_pressed(id: int) -> void:
	match id:
		0: _unequip()

func _unequip() -> void:
	EventBus.item_unequipped.emit(item)
	clear_slot()
