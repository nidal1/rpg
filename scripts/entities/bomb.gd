extends Area2D
class_name Bomb

signal arrow_hit(area: Area2D)

@export var speed: float = 100.0
@export var max_distance: float = 600.0
@export var explosion_animation_duration: float = 0.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0
var max_scale: float = 1.7
var current_scale: float = 1.0
var exploded: bool = false

func _ready() -> void:
	animated_sprite.play("bomb_spinning")

func _physics_process(delta: float) -> void:
	if exploded: return
	var movement: Vector2 = velocity * delta
	position += movement
	distance_traveled += movement.length()
	# TODO: scaling effect
	#if velocity.y != 0.05:
		## Progress men 0.0 hta 1.0
		#var progress: float = clamp(distance_traveled / max_distance, 0.0, 1.0)
		#
		## sin(progress * PI) kat'3ti قيمة men 0.0 hta 1.0 hta 0.0
		#var scale_factor: float = sin(progress * PI)
		#current_scale = 1.0 + (scale_factor * (max_scale - 1.0))
		
		#scale = Vector2(current_scale, current_scale)
	
	if distance_traveled > max_distance:
		queue_free()

func set_max_distance(value: float) -> void:
	max_distance = value

func get_animation_sprite() -> AnimatedSprite2D:
	return animated_sprite

func _on_area_entered(area: Area2D) -> void:
	exploded = true
	animated_sprite.play("bomb_explosion")
	await get_tree().create_timer(explosion_animation_duration).timeout
	if not is_instance_valid(self): return
	arrow_hit.emit(area)
	queue_free()
