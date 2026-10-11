extends Area2D
class_name Acorn

signal arrow_hit(area: Area2D)

@export var speed: float = 100.0
@export var max_distance: float = 600.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0

func _ready() -> void:
	animated_sprite.play("bone_spinning")

func _physics_process(delta: float) -> void:
	if velocity.x <= 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

	var movement: Vector2 = velocity * delta
	position += movement
	distance_traveled += movement.length()
	
	if distance_traveled > max_distance:
		queue_free()

func set_max_distance(value: float) -> void:
	max_distance = value

func get_animation_sprite() -> AnimatedSprite2D:
	return animated_sprite

func _on_area_entered(area: Area2D) -> void:
	if not is_instance_valid(self): return
	arrow_hit.emit(area)
	queue_free()
