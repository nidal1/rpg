extends Character

class_name Enemy

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var animation_BA_playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/basic_attack/BasicAttackStateMachine/playback"]

func _unhandled_input(event: InputEvent) -> void:
	pass  # override f Warrior/Mage only — Enemy ma3ndha input

# Warrior.gd — no @export, just load directly
func _ready() -> void:
	animation_tree.set_active(true)

func _load_classe(cls: CharacterClass):
	max_health = cls.max_health
	speed = cls.speed
	combo_chain = cls.combo_chain
	print("max_health: " + str(max_health) +" - speed: " + str(speed) + " - combo_chain: " , combo_chain )

# ─── State ───────────────────────────────────────────────

func _on_state_changed(new_state: State) -> void:
	match new_state:
		State.IDLE: animation_playback.travel(ANIM_IDLE)
		State.RUN:  animation_playback.travel(ANIM_RUN)
		State.ATTACKING: animation_playback.travel("basic_attack")

# ─── Movement ────────────────────────────────────────────

func _move() -> void:
	pass

func _idle() -> void:
	velocity = Vector2.ZERO
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
	# let _physics_process handle next state naturally

func _on_damage_received(amount: float) -> void:
	pass  # override f Warrior, Archer... (animation hit, vfx, etc.)

func _on_hitbox_area_entered(area: Area2D) -> void:
	print("From enemy class - hitbox - area: ", area )
