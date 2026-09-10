extends Control
class_name PotionSlot

@export var potion_type: Potion.PotionType = Potion.PotionType.HEALTH_POTION

# ─── Public Variables ────────────────────────────────────────────────────────

var potions: Array[Potion] = []
var slot_number: int

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var context_menu: PopupMenu = $ContextMenu
@onready var health_items_label: Label = $PotionsSizeLabel/HealthItemsLabel
@onready var health_potion_texture: TextureRect = $HealthPotionTexture

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	context_menu.add_item("Unequip", 0)
	context_menu.add_item("Consume", 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not potions.size():
			return
		context_menu.popup()
		# position = mouse position
		var off = Vector2(20, -50) + event.position
		context_menu.position = get_screen_position()  + off
		if not context_menu.id_pressed.is_connected(_on_context_menu_index_pressed):
			context_menu.id_pressed.connect(_on_context_menu_index_pressed)
	elif  event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and potions.size():
		consume()

func _on_context_menu_index_pressed(index: int) -> void:
	if index == 0:
		unequip()
	if index == 1:
		consume()

func unequip() -> void:
	if not potions.size():
		return

	var temp = potions.duplicate()
	for p in temp:
		EventBus.potions_unequipped.emit(p)
		potions.erase(p)
	
	health_potion_texture.texture = null
	health_items_label.text = "0"

func consume():
	if not potions.size():
		return
	
	var removed = potions.pop_back()
	EventBus.potions_consumed.emit(removed)
	if potions.size() <= 0:
		health_potion_texture.texture = null
		health_items_label.text = "0"
	else:
		health_items_label.text = str(potions.size())

func equip(new_potion: Potion) -> void:
	if not new_potion:
		return
	potions.append(new_potion)
	health_potion_texture.texture = new_potion.icon
	health_items_label.text = str(potions.size())

func get_potion_slot_type() -> Potion.PotionType:
	return potion_type
