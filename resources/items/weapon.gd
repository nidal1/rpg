class_name Weapon
extends Equipable

enum WeaponType {SWORD, AXE, BOW, STAFF, DAGGER}

@export var weapon_type: WeaponType
@export var base_attack_power: float = 10.0


func get_base_attack_power() -> float:
	# return a float number of one digit after comma
	return floor(base_attack_power * 10.0) / 10.0