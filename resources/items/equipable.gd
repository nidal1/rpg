class_name Equipable
extends Item


@export var player_type: CharacterClass.PlayerType = CharacterClass.PlayerType.ALL
@export var upgrade_level: int = 0
@export var tradable: bool = true
@export var gems_slots_count: int
@export var gems: Array[Gem] = [] # max 2-3 slots
@export var level: int = 1

func get_gems() -> Array[Gem]:
	return gems

func _add_gem(gem: Gem) -> void:
	if gems.size() < gems_slots_count:
		gems.append(gem)
	else:
		print("No more slots for gems")

func _remove_gem(gem: Gem) -> void:
	if gem in gems:
		gems.erase(gem)