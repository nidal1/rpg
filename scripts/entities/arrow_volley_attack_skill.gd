extends Area2D
class_name ArrowVolleyAttackSkill

@onready var particles: CPUParticles2D = $Particles

var skill: AttackSkill

func _get_attack_damage(defender_eva: float) -> Dictionary:
	if not StatsData.roll_hit(defender_eva):
		return {"hit": false, "is_crit": false, "damage": 0.0}

	var base_damage: float = skill.get_value()["value"]

	var is_crit: bool = (randf() * 100.0) < StatsData.get_crit_chance()
	var final_damage: float = base_damage * StatsData.get_crit_damage() if is_crit else base_damage

	return {"hit": true, "is_crit": is_crit, "damage": final_damage}


func _on_attack_cd_timeout() -> void:
	particles.emitting = false
	monitoring = false
	await get_tree().create_timer(2).timeout
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if area.name == "Hurtbox" and target_node.is_in_group("enemy"):
		var evasion = target_node.get_evasion()
		var hit_data: Dictionary = _get_attack_damage(evasion)
		target_node.take_damage(hit_data)
	pass # Replace with function body.
