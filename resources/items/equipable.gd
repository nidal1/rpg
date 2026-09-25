## DEPRECATED: Use EquipableItem instead.
## Legacy equipment base resource class kept for backwards compatibility.
class_name Equipable
extends Item

enum EquipmentCategory {WEAPON, ARMOR, ACCESSORY, SHIELD, CLOAK, PET}
enum EquipementType {HELMET, CHEST, GLOVES, BOOTS, SHIELD, WEAPON, RING, AMULET, CLOAK, PET}

@export var level: int = 1
@export var player_type: CharacterClass.PlayerType = CharacterClass.PlayerType.ALL
@export var item_category: EquipmentCategory = EquipmentCategory.WEAPON
