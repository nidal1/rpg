extends CharacterBody2D
class_name Character

enum State {IDLE, RUN, ATTACKING}

var direction: Vector2 = Vector2.ZERO
var last_facing_dir: float = 1.0
var current_state: State = State.IDLE
var max_health: float = 100.0


# ─── Virtual functions ────────────────────────────────────────────
func _move() -> void: pass
func _idle() -> void: pass
func _attack() -> void: pass
func _die() -> void: pass
func _on_damage_received() -> void: pass
func _play_movement_animation() -> void: pass
func _play_idle_animation() -> void: pass
func _on_state_changed(new_state: State) -> void: pass
func _get_attack_damage() -> float: return 0.0

# ─── State ───────────────────────────────────────────────
func _set_state(new_state: State) -> void:
	if current_state == new_state: return
	current_state = new_state
	_on_state_changed(new_state)

# ─── Combat ──────────────────────────────────────────────
func take_damage(amount: float) -> void:
	max_health -= amount
	_on_damage_received()
