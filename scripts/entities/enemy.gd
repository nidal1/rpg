# Enemy.gd
extends Character
class_name Enemy

signal on_spawned(spawn_position: Vector2)

@export var enemy_params: EnemyParams

@onready var nav_agent: NavigationAgent2D = $NavigationAgent

var is_target_reached = false
var can_attack = true
var target: CharacterBody2D = null

var attack_cooldown: float
var attack_range: float
var attack_damage: float
var speed: float
var enemy_name: String = ""

var spawn_position: Vector2

# ─── Virtual functions ─────────────────────────────d───────────────
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
	if enemy_params:
		_load_params(enemy_params)
		on_spawned.connect(_on_spawned)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		if current_state != State.PATROL:
			_patrol()
		return
	# Update distance and state
	var dist = global_position.distance_to(target.global_position)
	is_target_reached = dist <= attack_range
	if is_target_reached:
		velocity = Vector2.ZERO # Stop moving to attack
		if can_attack:
			_attack()
		else:
			# While waiting for cooldown, look at player
			_set_state(State.IDLE)
	else:
		_chase_target()
	
	move_and_slide()
	

# ─── Movement ────────────────────────────────────────────
func _chase_target() -> void:
	if not is_instance_valid(target):
		target = null
		_set_state(State.PATROL)
		return

	_set_state(State.CHASE)

	nav_agent.target_position = target.global_position
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	if direction.length() > 0:
		velocity = direction * speed
		if velocity.x != 0:
			last_facing_dir = sign(velocity.x)
		
		_play_movement_animation()

func _patrol() -> void:
	nav_agent.target_position = spawn_position
	var next_pos = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_pos)
	if direction.length() > 0:
		velocity = direction * speed
		if velocity.x != 0:
			last_facing_dir = sign(velocity.x)
		
		_play_movement_animation()
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()

# ─── Combat ──────────────────────────────────────────────
func _attack() -> void:
	can_attack = false
	_set_state(State.ATTACKING)
	_play_attack_animation()

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self ): return
	can_attack = true

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
		_die()

func _die() -> void:
	queue_free()

func _on_spawned(_spawn_position: Vector2):
	spawn_position = _spawn_position


# ─── Detection ───────────────────────────────────────────
func _on_detection_zone_body_entered(body: Node2D) -> void:
	print("BODY ENTERED THE DETECTION ZONE")
	if body.is_in_group("player"):
		target = body
		_set_state(State.CHASE)

func _on_detection_zone_body_exited(body: Node2D) -> void:
	print("BODY EXITED THE DETECTION ZONE")
	if body.is_in_group("player"):
		target = null
		is_target_reached = false
		_set_state(State.PATROL)
