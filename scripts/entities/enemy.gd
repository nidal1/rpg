extends Character
class_name Enemy

signal on_spawned(spawn_position: Vector2)
signal on_died
signal on_wander_finished

@export var enemy_params: EnemyParams

@onready var nav_agent: NavigationAgent2D = $NavigationAgent

@onready var wander_cd = $WanderCD

var is_target_reached = false
var can_attack = true
var target: CharacterBody2D = null

var attack_cooldown: float
var attack_range: float
var attack_damage: float
var speed: float
var enemy_name: String = ""

var wander_cd_time: float = 5.0
var is_wandering: bool = false
var spawn_position: Vector2

# ─── Virtual functions ────────────────────────────────────────────
func _play_attack_animation() -> void: pass

func _load_params(params: EnemyParams) -> void:
	max_health = params.max_health
	speed = params.speed
	attack_damage = params.attack_damage
	attack_range = params.attack_range
	attack_cooldown = params.attack_cooldown
	name = params.enemy_name

func _ready() -> void:
	super._ready()
	wander_cd.wait_time = wander_cd_time

func _physics_process(_delta: float) -> void:
	move_and_slide()
	

# ─── Movement ────────────────────────────────────────────

func _idle() -> void:
	direction = Vector2.ZERO
	velocity = Vector2.ZERO
	if animation_playback and animation_tree and animation_tree.is_active():
		animation_playback.travel("idle")
		_play_idle_animation()

func _move() -> void:
	velocity = direction.normalized() * speed
	if velocity.x != 0:
		last_facing_dir = sign(velocity.x)
		if animation_playback and animation_tree and animation_tree.is_active():
			animation_playback.travel("run")
			_play_movement_animation()

func _move_to_position(_target_position: Vector2) -> void:
	nav_agent.target_position = _target_position
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	if global_position.distance_to(nav_agent.target_position) < 1:
		print("Target reached")
		return
	_move()

func _chase_target() -> void:
	if not is_instance_valid(target): return
	nav_agent.target_position = target.global_position
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	_move()

func _patrol() -> void:
	_move_to_position(spawn_position)

# ─── Combat ──────────────────────────────────────────────
func _attack() -> void:
	can_attack = false
	animation_playback.travel("basic_attack")
	_play_attack_animation()

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self ): return
	can_attack = true

func _target_reached() -> bool:
	return target and global_position.distance_to(target.global_position) < attack_range

func _get_attack_damage() -> float:
	return attack_damage

func _flash_hit() -> void:
	modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self ): return
	modulate = Color.WHITE

func _on_damage_received() -> void:
	_flash_hit()
	if max_health <= 0:
		state_machine.transition_to("enemydeadstate")

func _die() -> void:
	queue_free()

func _wander(_to_position: Vector2) -> void:
	if global_position.distance_to(_to_position) < 1:
		velocity = Vector2.ZERO
		on_wander_finished.emit()
	else:
		_move_to_position(_to_position)

func _stop_wandering() -> void:
	wander_cd.stop()

# ─── Detection ───────────────────────────────────────────
func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = null

func _on_wander_cd_timeout() -> void:
	state_machine.transition_to("enemywanderstate")
