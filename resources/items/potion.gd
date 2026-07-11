extends Consumable
class_name Potion

enum PotionType {HEALTH_POTION, MANA_POTION}

@export var potion_type: PotionType = PotionType.HEALTH_POTION
@export var heal_percentage: int = 10

func get_potion_effect():
	return {
		"potion_type": potion_type,
		"heal_percentage": heal_percentage
	}