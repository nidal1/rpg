extends Panel
class_name MerchantStoreSlot

var slot_index: int
var item: DataItem

signal mouse_enter(item: DataItem)
signal mouse_exit()
signal mouse_clicked(item: DataItem)

@onready var merchant_store_slot_icon: TextureRect = $CenterContainer/MerchantStoreSlotIcon

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not item:
			return

		mouse_clicked.emit(item)


func set_item(_item:DataItem):
	if _item != null:
		item = _item
		merchant_store_slot_icon.texture = _item.get_item_texture()

func clear_slot(): 
	if item:
		item = null
		merchant_store_slot_icon.texture = null


func _on_mouse_entered() -> void:
	mouse_enter.emit(item)


func _on_mouse_exited() -> void:
	mouse_exit.emit()
