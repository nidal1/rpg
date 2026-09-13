extends NPC
class_name Merchant

@export var waypoints: Array[Marker2D] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var wander_cd: Timer = $WanderCD
@onready var interaction_label: Label = $InteractionLabel

var __initial_location: Vector2
var __random_waypoint: Vector2
var __is_wandering = false
var __is_runing = false
var __is_at_position = false
var __can_interact = false

func _ready() -> void:
	__initial_location = global_position
	wander_cd.start()

func _physics_process(delta: float) -> void:
	if __is_wandering :
		if global_position.distance_to(__random_waypoint) <= 0.5:
			if __random_waypoint !=  __initial_location:
				__is_at_position = true
			
			__is_wandering = false
			wander_cd.start()
			_idle()
		else:
			_move()
			move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_E and __can_interact:
			_interact()


func _move() -> void:
	__is_runing = true
	_play_movement_animation()
	var point_gp = __random_waypoint
	var gp = global_position
	direction = gp.direction_to(point_gp).normalized()
	speed = 40
	
	velocity = direction * speed

func _play_idle_animation() -> void:
	direction = Vector2.ZERO
	speed = 0
	animated_sprite.play("idle_left")
	animated_sprite.flip_h = last_facing_dir


func _play_movement_animation() -> void:
	
	if velocity.x > 0:
		last_facing_dir = false
	elif velocity.x < 0:
		last_facing_dir = true
	
	animated_sprite.play("run_left")
	animated_sprite.flip_h = last_facing_dir


func _choose_random_point_position() -> Vector2:
	if not waypoints.size():
		return Vector2.ZERO
		
	return waypoints.pick_random().global_position


func _on_wander_cd_timeout() -> void:
	if __is_at_position:
		__random_waypoint = __initial_location
		__is_at_position = false
	else:
		__random_waypoint = _choose_random_point_position()
	
	__is_wandering = true
	_wander()

func _toggle_interact_label():
	interaction_label.visible = !interaction_label.visible

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_interaction_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_toggle_interact_label()
		__can_interact = true

func _on_interaction_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_toggle_interact_label()
		__can_interact = false
