extends Area2D
class_name DropItem

@onready var drop_item_image: Sprite2D = $DropItemImage

var item: Item

func _ready() -> void:
	if item and drop_item_image:
		drop_item_image.texture = item.icon

func assign_drop_item_image(new_item: Item) -> void:
	item = new_item
	if is_inside_tree() and drop_item_image:
		drop_item_image.texture = item.icon
