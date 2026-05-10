# patrol_state.gd
extends State
class_name PatrolState

func enter() -> void:
	# Start with idle animation, _patrol will switch to run if moving
	if actor.animation_playback:
		actor.animation_playback.travel("run")

func physics_update(_delta: float) -> void:
	actor._patrol()

	# If we are back at spawn and velocity is zero, transition to idlestate
	if actor.global_position.distance_to(actor.spawn_position) <= 1.0:
		actor.velocity = Vector2.ZERO
		transitioned.emit("idlestate")
