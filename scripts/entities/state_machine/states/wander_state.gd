extends State
class_name WanderState

enum Directions {LEFT, RIGHT, UP, DOWN}

var random_position: Vector2


func enter() -> void:
	actor.on_wander_finished.connect(_on_wander_finished)
	var random_direction = _random_direction()
	if random_direction == Vector2.ZERO:
		return
	random_position = actor.global_position + random_direction * 100

func physics_update(_delta: float) -> void:
	actor._wander(random_position)

func _on_wander_finished() -> void:
	actor.on_wander_finished.disconnect(_on_wander_finished)
	transitioned.emit("idlestate")

func _random_direction() -> Vector2:
	var random_direction = Directions.values().pick_random()
	match random_direction:
		Directions.LEFT:
			return Vector2.LEFT
		Directions.RIGHT:
			return Vector2.RIGHT
		Directions.UP:
			return Vector2.UP
		Directions.DOWN:
			return Vector2.DOWN
	return Vector2.ZERO