extends Area2D
class_name WaterBullet

signal bullet_hit(area: Area2D)

@export var speed: float = 300.0
@export var max_distance: float = 600.0

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0

func _physics_process(delta: float) -> void:
	var movement = velocity * delta
	position += movement
	distance_traveled += movement.length()
	if distance_traveled > max_distance:
		queue_free()

func set_max_distance(value: float) -> void:
	max_distance = value


func _on_area_entered(area: Area2D) -> void:
	bullet_hit.emit(area)
	queue_free()