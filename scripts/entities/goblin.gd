## Goblin
## A specific enemy type that attacks the player in close range.
extends Enemy
class_name Goblin

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	super._ready()
	animation_tree = $AnimationTree
	animation_playback = animation_tree["parameters/playback"]
	animation_tree.set_active(true)

# ─── Overridden Virtual Methods ──────────────────────────────────────────────
func _play_movement_animation() -> void:
	animation_tree.set("parameters/run/blend_position", last_facing_dir)

func _play_idle_animation() -> void:
	animation_tree.set("parameters/idle/blend_position", last_facing_dir)

func _play_attack_animation() -> void:
	animation_tree.set("parameters/basic_attack/BlendSpace1D/blend_position", last_facing_dir)

func _on_state_changed(new_state: DeprecatedState) -> void:
	match new_state:
		DeprecatedState.IDLE, DeprecatedState.PATROL:
			animation_playback.travel(ANIM_IDLE)
			_play_idle_animation()
		DeprecatedState.RUN, DeprecatedState.CHASE:
			animation_playback.travel(ANIM_RUN)
			_play_movement_animation()
		DeprecatedState.ATTACKING:
			animation_playback.travel("basic_attack")
			_play_attack_animation()

# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	var target_node = area.get_parent()
	if target_node.is_in_group("player"):
		target_node.take_damage(_get_attack_damage())
