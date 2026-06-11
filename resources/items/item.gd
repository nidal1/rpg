class_name Item
extends Resource

enum ItemType {EQUIPABLE, CONSUMABLE, QUEST, ENCHANTMENT}
enum Rarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType
@export var rarity: Rarity = Rarity.COMMON