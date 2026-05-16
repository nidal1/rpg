extends Sprite2D
class_name Arrow

signal _on_arrow_hit(area: Area2D)


@export var speed: float = 1000.0
var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

@onready var arrow_lifetime: Timer = $ArrowLifetime

func _ready() -> void:
	arrow_lifetime.start()

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_hitbox_area_entered(area: Area2D) -> void:
	_on_arrow_hit.emit(area)
	queue_free()


func _on_arrow_lifetime_timeout() -> void:
	queue_free()
