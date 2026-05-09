extends Player
class_name Warrior

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var animation_BA_playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/basic_attack/BasicAttackStateMachine/playback"]
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	super._ready()
	animation_tree.set_active(true)
	var cls = load("res://resources/classes/warrior.tres")
	_load_classe(cls)

func _on_state_changed(new_state: State) -> void:
	match new_state:
		State.IDLE: animation_playback.travel(ANIM_IDLE)
		State.RUN: animation_playback.travel(ANIM_RUN)
		State.ATTACKING: animation_playback.travel("basic_attack")

func _play_movement_animation() -> void:
	animation_tree.set("parameters/run/blend_position", last_facing_dir)

func _play_idle_animation() -> void:
	animation_tree.set("parameters/idle/blend_position", last_facing_dir)

func _play_attack_animation(attack: AttackData) -> void:
	animation_tree.set(
	"parameters/basic_attack/BasicAttackStateMachine/%s/blend_position" % attack.anim_name,
	last_facing_dir
	)
	animation_BA_playback.travel(attack.anim_name)

func _end_combo() -> void:
	animation_BA_playback.travel("End")
	super._end_combo()


func _on_hitbox_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("enemy"):
		target_node.take_damage(_get_attack_damage())
