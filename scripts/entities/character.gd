extends CharacterBody2D

class_name Character

enum State { IDLE, RUN, ATTACKING }

@export var speed = 300.0

const ANIM_IDLE = "idle"
const ANIM_RUN = "run"
const ANIM_ATTACK1 = "attack1"
const ANIM_ATTACK2 = "attack2"


@onready var combo_timer: Timer = $ComboAttackCD


var direction: Vector2 = Vector2.ZERO
var last_facing_dir: float = 1.0
var current_state: State = State.IDLE
var combo_index: int = -1       # which attack we're on (-1 = not attacking)
var combo_queued: bool = false   # player pressed attack during current attack
var max_health = 100
var combo_chain: Array[AttackData]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_attack_pressed()

func _physics_process(_delta: float) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if current_state != State.ATTACKING:
		if direction != Vector2.ZERO:
			_set_state(State.RUN)
			_move()
		else:
			_set_state(State.IDLE)
			_idle()
		move_and_slide()

# ─── State ───────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	if current_state == new_state: return
	current_state = new_state
	_on_state_changed(new_state)

func _on_state_changed(new_state: State) -> void: pass
# ─── Movement ────────────────────────────────────────────

func _move() -> void:
	pass

func _idle() -> void:
	pass

# ─── Combo ───────────────────────────────────────────────
func _attack():
	if current_state == State.ATTACKING:
		# queue next only if there's a next attack in chain
		if combo_index < combo_chain.size() - 1:
			combo_queued = true
		return
	_start_combo()


func _on_attack_pressed() -> void:
	if combo_chain.size() > 0: _attack()

func _start_combo() -> void:
	combo_index = 0
	combo_queued = false
	_set_state(State.ATTACKING)
	_execute_attack()

func _execute_attack() -> void:
	var attack: AttackData = combo_chain[combo_index]
	_play_attack_animation(attack)

	# start combo window timer
	combo_timer.wait_time = attack.combo_window
	combo_timer.start()

func _play_attack_animation(attack: AttackData) -> void: pass

func _end_combo() -> void:
	combo_index = -1
	combo_queued = false
	current_state = State.IDLE
	# let _physics_process handle next state naturally

func _get_attack_damage() -> float:
	if combo_index < 0 or combo_index >= combo_chain.size(): return 0.0
	return combo_chain[combo_index].damage

func take_damage(amount: float) -> void:
	max_health -= amount
	print("health: ", max_health)
	_on_damage_received(amount)  # virtual

func _on_damage_received(amount: float) -> void:
	pass  # override f Warrior, Archer... (animation hit, vfx, etc.)

func _on_combo_attack_cd_timeout() -> void:
	if combo_queued and combo_index < combo_chain.size() - 1:
		# advance to next attack in chain
		combo_index += 1
		combo_queued = false
		_execute_attack()
	else:
		# end of combo
		_end_combo()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("From character class - hurtbox - area: ", area)
