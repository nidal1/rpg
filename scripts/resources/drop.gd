## DropItem
## Represents a physical item dropped in the game world that can be picked up.
extends Area2D
class_name DropItem

# ─── Public Variables ────────────────────────────────────────────────────────
## The item resource associated with this physical drop.
var item: Item

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var drop_item_image: Sprite2D = $DropItemImage

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	if item and drop_item_image:
		drop_item_image.texture = item.icon

# ─── Public Methods ──────────────────────────────────────────────────────────
## Assigns a new item resource to this drop and updates its visual representation.
func assign_drop_item_image(new_item: Item) -> void:
	item = new_item
	if is_inside_tree() and drop_item_image:
		drop_item_image.texture = item.icon
