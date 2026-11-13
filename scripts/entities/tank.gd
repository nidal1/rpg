extends Player
class_name Tank

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	var cls = load("res://resources/classes/tank.tres")
	_load_classe(cls)

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if area.name == "Hurtbox" and target_node.is_in_group("enemy"):
		var damage: float = _get_attack_damage()
		target_node.take_damage(damage)
