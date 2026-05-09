extends Enemy
class_name Goblin

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

func _ready() -> void:
	super._ready()
	animation_tree.set_active(true)

func _on_state_changed(new_state: State) -> void:
	match new_state:
		State.IDLE, State.PATROL:
			animation_playback.travel(ANIM_IDLE)
			_play_idle_animation()
		State.RUN, State.CHASE:
			animation_playback.travel(ANIM_RUN)
			_play_movement_animation()
		State.ATTACKING:
			animation_playback.travel("basic_attack")
			_play_attack_animation()

func _play_movement_animation() -> void:
	animation_tree.set("parameters/run/blend_position", last_facing_dir)

func _play_idle_animation() -> void:
	animation_tree.set("parameters/idle/blend_position", last_facing_dir)

func _play_attack_animation() -> void:
	animation_tree.set("parameters/basic_attack/BlendSpace1D/blend_position", last_facing_dir)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("player"):
		target_node.take_damage(_get_attack_damage())
