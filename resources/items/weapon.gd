class_name Weapon
extends Item

enum WeaponType {SWORD, AXE, BOW, STAFF, DAGGER}

@export var weapon_type: WeaponType
@export var base_attack_power: float = 10.0
@export var level: int = 1
@export var gems: Array[Gem] = [] # max 2-3 slots

func get_total_attack_power() -> float:
	var total = base_attack_power
	for gem in gems:
		total += gem.get_atk_bonus()
	return total