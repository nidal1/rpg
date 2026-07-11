extends Control
class_name PotionSlot

@export var potion_type: Potion.PotionType = Potion.PotionType.HEALTH_POTION

# ─── Public Variables ────────────────────────────────────────────────────────

var potion: Potion = null
var slot_number: int

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var context_menu: PopupMenu = $ContextMenu
@onready var health_items_label: Label = $PotionsSizeLabel/HealthItemsLabel
@onready var health_potion_texture_button: TextureButton = $HealthPotionTextureButton

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	context_menu.add_item("Unequip", 0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not potion:
			return
		context_menu.popup()
		# position = mouse position
		context_menu.position = get_screen_position() + event.position
		print("context menu popup for potion slot %d" % slot_number)

func _on_context_menu_index_pressed(index: int) -> void:
	if index == 0:
		unequip()

func unequip() -> void:
	if not potion:
		return
	
	potion = null
	health_potion_texture_button.texture_normal = null
	health_items_label.text = "0"

func equip(new_potion: Potion) -> void:
	if not new_potion:
		return
	potion = new_potion
	health_potion_texture_button.texture_normal = new_potion.icon
	health_items_label.text = "1"

func get_potion_slot_type() -> Potion.PotionType:
	return potion_type
