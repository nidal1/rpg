class_name Item
extends Resource

enum ItemType {WEAPON, ARMOR, GEM, CONSUMABLE}
enum Rarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType
@export var rarity: Rarity = Rarity.COMMON