## DropItem
## Represents a physical item dropped in the game world that can be picked up.
extends Area2D
class_name DropItem

# ─── Exported Variables ──────────────────────────────────────────────────────
@export var despawn_time: float = 30.0

# ─── Public Variables ────────────────────────────────────────────────────────
## The item resource associated with this physical drop.
var item: Item

# ─── OnReady Variables ───────────────────────────────────────────────────────
@onready var drop_item_image: Sprite2D = $DropItemImage
@onready var drop_cd: Timer = $DropCD

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	if item and drop_item_image:
		drop_item_image.texture = item.icon

	drop_cd.wait_time = despawn_time
	drop_cd.start()

# ─── Public Methods ──────────────────────────────────────────────────────────
## Assigns a new item resource to this drop and updates its visual representation.
func assign_drop_item_image(new_item: Item) -> void:
	item = new_item
	if is_inside_tree() and drop_item_image:
		drop_item_image.texture = item.icon


func _on_drop_cd_timeout() -> void:
	queue_free()
