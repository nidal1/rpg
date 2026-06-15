class_name Armor
extends Equipable

enum ArmorType {HELMET, CHEST, BOOTS, GLOVES, SHIELD, RING, AMULET, CLOAK}

@export var armor_type: ArmorType
@export var base_defense: float = 5.0
@export var base_resist: float = 0.0
@export var upgrade_resistance_level: int = 0

func get_total_defense() -> float:
	var total = base_defense
	for gem in gems:
		total += gem.get_def_bonus()
	return total

func get_total_resistance() -> float:
	var total = base_resist
	for gem in gems:
		total += gem.get_resist_bonus()
	return total
