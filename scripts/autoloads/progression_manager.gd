## ProgressionManager
## utility class and autoload for RPG progression, scaling math, 
## enemy XP yield, damage calculations, and animation speed scaling.
extends Node

# ─── Enums ───────────────────────────────────────────────────────────────────
enum EnemyRank {
	NORMAL,
	CAPTAIN,
	BOSS
}

# ─── Constants & Configuration Defaults ──────────────────────────────────────
const DEFAULT_LEVEL_SCALER: float = 1.2
const BASE_PLAYER_XP: int = 75

const DEFAULT_BASE_DAMAGE: float = 10.0
const DAMAGE_LINEAR_SCALE: float = 2.5
const DAMAGE_CURVE_COEFF: float = 0.8

const MIN_ATTACK_TIMESCALE: float = 0.3
const MAX_ATTACK_TIMESCALE: float = 1.0
const MAX_SPEED_SCALING_LEVEL: int = 40

# Rank Multipliers
const RANK_XP_MULTIPLIERS: Dictionary = {
	EnemyRank.NORMAL: 1.0,
	EnemyRank.CAPTAIN: 2.5,
	EnemyRank.BOSS: 5.0
}

const RANK_DAMAGE_MULTIPLIERS: Dictionary = {
	EnemyRank.NORMAL: 1.0,
	EnemyRank.CAPTAIN: 1.75,
	EnemyRank.BOSS: 3.0
}

# ─── Public Methods ───────────────────────────────────────────────────

## 1. Player XP Requirement Curve (Leveling System)
## Calculates the total XP required for a player to advance from level to level + 1.
## Uses polynomial-modified exponential scaling with level_scaler to ensure
## smooth early progression without hitting an exponential brick wall in end-game.
func get_required_xp_for_level(level: int, level_scaler: float = DEFAULT_LEVEL_SCALER) -> int:
	if level <= 1:
		return BASE_PLAYER_XP
	
	var lvl_offset: float = float(level - 1)
	# Polynomial scaling driven by level_scaler:
	# Base_XP * (1 + (N-1)^level_scaler * 0.6 + (N-1) * 0.4)
	var curve_term: float = pow(lvl_offset, level_scaler) * 0.6
	var linear_term: float = lvl_offset * 0.4
	var total_multiplier: float = 1.0 + curve_term + linear_term
	
	return int(round(BASE_PLAYER_XP * total_multiplier))


## 2. Target Mobs Per Level Curve
## Returns the target number of Normal mobs needed to level up at a given player level.
## Scales smoothly from ~12 mobs at Level 1 to ~40 mobs at Level 50.
func get_target_mobs_per_level(level: int) -> float:
	var progress: float = clamp(float(level - 1) / 49.0, 0.0, 1.0)
	return 12.0 + 28.0 * pow(progress, 0.85)


## 3. Enemy XP Yield Formula (Per Level & Rank)
## Calculates XP given by an enemy upon death based on level, rank, and optional level difference.
func get_enemy_xp_yield(enemy_level: int, rank: EnemyRank = EnemyRank.NORMAL, player_level: int = -1) -> int:
	var safe_enemy_lvl: int = max(1, enemy_level)
	var req_xp_at_enemy_lvl: int = get_required_xp_for_level(safe_enemy_lvl)
	var mobs_needed: float = get_target_mobs_per_level(safe_enemy_lvl)
	
	# Base XP yield for a Normal enemy at this level
	var base_mob_xp: float = max(1.0, float(req_xp_at_enemy_lvl) / mobs_needed)
	
	# Apply Rank Multiplier
	var rank_mult: float = RANK_XP_MULTIPLIERS.get(rank, 1.0)
	var final_xp: float = base_mob_xp * rank_mult
	
	# Apply Level Difference Adjustment if player_level is specified
	if player_level > 0:
		var level_diff: int = enemy_level - player_level
		# Clamp level modifier between 0.2x (-8 levels below) and 1.5x (+5 levels above)
		var diff_factor: float = clamp(1.0 + 0.1 * float(level_diff), 0.2, 1.5)
		final_xp *= diff_factor
		
	return int(round(final_xp))


## 4. Enemy Physical Damage Scaling
## Calculates Enemy Physical Damage: Final Damage = Base Damage + (Level Scaling Component)
## Scales cleanly across maps without becoming unmitigatable.
func get_enemy_damage(enemy_level: int, rank: EnemyRank = EnemyRank.NORMAL, base_damage: float = DEFAULT_BASE_DAMAGE) -> float:
	var lvl_offset: float = max(0.0, float(enemy_level - 1))
	
	# Level Scaling Component: Linear + sub-quadratic curve
	var level_component: float = (DAMAGE_LINEAR_SCALE * lvl_offset) + (DAMAGE_CURVE_COEFF * pow(lvl_offset, 1.12))
	var unscaled_damage: float = base_damage + level_component
	
	var rank_mult: float = RANK_DAMAGE_MULTIPLIERS.get(rank, 1.0)
	return round((unscaled_damage * rank_mult) * 10.0) / 10.0


## 5. Attack Animation & Action Speed Scaling (Capped at 1.0 max)
## Calculates Animation TimeScale dynamically from min_speed (0.5x) to a hard cap of 1.0x at max_speed_level (40).
func get_enemy_attack_speed(enemy_level: int, min_speed: float = MIN_ATTACK_TIMESCALE, max_speed_level: int = MAX_SPEED_SCALING_LEVEL) -> float:
	if enemy_level <= 1:
		return min_speed
	
	var progress: float = clamp(float(enemy_level - 1) / float(max_speed_level - 1), 0.0, 1.0)
	var timescale: float = min_speed + (MAX_ATTACK_TIMESCALE - min_speed) * pow(progress, 0.75)
	
	# HARD CAP ENFORCEMENT: Never exceed 1.0x
	return min(MAX_ATTACK_TIMESCALE, round(timescale * 1000.0) / 1000.0)


## 6. Total Attack Cycle Time Calculation
## Total Attack Cycle = (base_anim_duration / current_timescale) + base_recovery_delay
func get_total_attack_cycle(base_anim_duration: float, current_timescale: float, base_recovery_delay: float) -> float:
	var safe_timescale: float = max(0.1, current_timescale)
	return (base_anim_duration / safe_timescale) + base_recovery_delay


## 7. Dynamic AnimationTree TimeScale Updater
## Updates the specified AnimationTree parameter dynamically for an enemy or character.
func update_animation_timescale(anim_tree: AnimationTree, current_timescale: float, parameter_path: String = "parameters/TimeScale/scale") -> void:
	if is_instance_valid(anim_tree) and anim_tree.is_active():
		anim_tree.set(parameter_path, current_timescale)
