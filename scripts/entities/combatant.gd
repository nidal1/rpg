## Combatant
## Base class for combat entities (Player, Enemy) extending Character.
## Handles health, mana, stats, combat animations, damage calculations, and hit flashing.
extends Character
class_name Combatant


## Playback for basic attacks.
var animation_BA_playback: AnimationNodeStateMachinePlayback = null

# ─── Public Methods ──────────────────────────────────────────────────────────
## Applies damage to the combatant using defense reduction logic.
func take_damage(amount: float) -> void: pass

# ─── Virtual Methods ─────────────────────────────────────────────────────────
## Virtual method for attack logic.
func _attack() -> void: pass

## Virtual method for death logic.
func _die() -> void: pass

## Virtual method called when damage is received.
func _on_damage_received() -> void: pass

## Virtual method that returns the current attack damage.
func _get_attack_damage() -> float: return 0.0

## Virtual method that returns the current defense.
func _get_defense() -> float: return 0.0

# ─── Private / Protected Methods ─────────────────────────────────────────────
## Flashes the combatant red to indicate damage taken.
func _flash_hit() -> void:
	modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self): return
	modulate = Color.WHITE
