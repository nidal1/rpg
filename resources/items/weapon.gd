class_name Weapon
extends Equipable

enum WeaponType {SWORD, AXE, BOW, STAFF, DAGGER}

@export var weapon_type: WeaponType
@export var base_attack_power: float = 10.0


func get_total_attack_power() -> float:
	var total = base_attack_power
	for gem in gems:
		total += gem.get_atk_bonus()
	# return a float number of one digit after comma
	return floor(total * 10.0) / 10.0