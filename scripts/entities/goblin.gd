extends Enemy
class_name Goblin


func _on_damage_received() -> void:
	print("Enemy hit! health remaining: ", max_health)
	if max_health <= 0:
		_die()

func _die() -> void:
	queue_free()
