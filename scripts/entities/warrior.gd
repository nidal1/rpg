## Warrior
## A melee player class focused on close-range combat.
extends Player
class_name Warrior

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	var cls = load("res://resources/classes/warrior.tres")
	_load_classe(cls)

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if area.name == "Hurtbox" and target_node.is_in_group("enemy"):
		target_node.take_damage(_get_attack_damage())
