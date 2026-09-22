extends Panel
class_name MerchantBuyItemModal

signal buy_button_clicked(value: float)

var value: float = 0

func get_value():
	return value

func _on_quantity_input_value_changed(_value: float) -> void:
	value = _value


func _on_cancel_button_pressed() -> void:
	queue_free()


func _on_buy_button_pressed() -> void:
	buy_button_clicked.emit(value)
	queue_free()
