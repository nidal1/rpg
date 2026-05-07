# Enemy.gd
extends Character
class_name Enemy

@export var speed: float = 150.0
@export var damage: float = 10.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var detection_zone: Area2D = $DetectionZone

var target: CharacterBody2D = null

func _ready() -> void:
	detection_zone.body_entered.connect(_on_detection_zone_body_entered)
	detection_zone.body_exited.connect(_on_detection_zone_body_exited)

func _physics_process(_delta: float) -> void:
	if target:
		_chase_target()
	else:
		_patrol()
	move_and_slide()

# ─── Detection ───────────────────────────────────────────
func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = null

# ─── Movement ────────────────────────────────────────────
func _chase_target() -> void:
	nav_agent.target_position = target.global_position
	var next_pos = nav_agent.get_next_path_position()
	direction = (next_pos - global_position).normalized()
	velocity = direction * speed
	if velocity.x != 0:
		last_facing_dir = sign(velocity.x)
	_play_movement_animation()

func _patrol() -> void:
	velocity = Vector2.ZERO
	_play_movement_animation()

# ─── Combat ──────────────────────────────────────────────
func _get_attack_damage() -> float:
	return damage

func take_damage(amount: float) -> void:
	super.take_damage(amount)

func _on_damage_received() -> void:
	print("Enemy hit! health remaining: ", max_health)
	if max_health <= 0:
		_die()

func _die() -> void:
	queue_free()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	print(area)
