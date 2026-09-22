extends Resource
class_name DataItem

@export var id: String
@export var item_name: String
@export var item_player_class: CharacterClass.PlayerType
@export var item_type: Equipable.EquipementType
@export var required_level: int
@export var base_damage: int
@export var price: int
@export var grid_coordinate: Vector2

var cell_size: Vector2

func _init(
	_id: String = "",
	_item_name: String = "",
	_item_player_class: CharacterClass.PlayerType = CharacterClass.PlayerType.ALL,
	_item_type: Equipable.EquipementType = Equipable.EquipementType.AXE,
	_grid_coordinate: Vector2 = Vector2.ZERO,
	_required_level: int = 1,
	_base_damage: int = 0,
	_price: int = 0,
	_cell_size: Vector2 = Vector2(64, 64)) -> void:
	
	id = _id
	item_name = _item_name
	item_type = _item_type
	item_player_class = _item_player_class
	grid_coordinate = _grid_coordinate
	required_level = _required_level
	base_damage = _base_damage
	price = _price
	cell_size = _cell_size

func get_category_from_type(type: Equipable.EquipementType) -> Equipable.EquipmentCategory:
	match type:
		Equipable.EquipementType.RING, Equipable.EquipementType.NECKLACE:
			return Equipable.EquipmentCategory.ACCESSORY
			
		Equipable.EquipementType.SHIELD, Equipable.EquipementType.CHEST, Equipable.EquipementType.HEAD, Equipable.EquipementType.LEGS_FEET, Equipable.EquipementType.FEET:
			return Equipable.EquipmentCategory.ARMOR
			
		_:
			# (Dagger, Sword, Bow, Staff, etc.) Weapons
			return Equipable.EquipmentCategory.WEAPON

func get_item_texture() -> AtlasTexture:
	var wep_tex_path = "res://assets/sprites/items/weapons.png"
	var arm_tex_path = "res://assets/sprites/items/armors.png"
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(wep_tex_path if get_category_from_type(item_type) == Equipable.EquipmentCategory.WEAPON else arm_tex_path)
	atlas_tex.region = Rect2(
		grid_coordinate.x * cell_size.x,
		grid_coordinate.y * cell_size.y,
		cell_size.x,
		cell_size.y
	)
	return atlas_tex
