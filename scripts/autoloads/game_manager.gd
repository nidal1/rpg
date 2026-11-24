## GameManager
## Coordinates game systems through specialized managers.
extends Node2D

# ─── Public Variables ────────────────────────────────────────────────────────
var player_ref: Character = null
var level_scaler: float = 1.2
var stats_manager: StatsManager = StatsManager.new()
var skills_manager: SkillsManager = SkillsManager.new()

# ─── Manager Instances ───────────────────────────────────────────────────────
var loot_manager: LootManager
var equipment_manager: EquipmentManager
var targeting_manager: TargetingManager
var input_manager: InputManager

# ─── Built-in Methods ────────────────────────────────────────────────────────
func _ready() -> void:
	_initialize_managers()
	connect_global_events()
	input_manager.initialize_cursors()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		targeting_manager.handle_mouse_targeting(
			get_global_mouse_position(),
			get_viewport(),
			player_ref as Player
		)

# ─── Public Methods ──────────────────────────────────────────────────────────
## Registers the player with the Game Manager and initializes data.
func register_player(player: Character) -> void:
	player_ref = player
	stats_manager.initialize(player)
	skills_manager.initialize(player.character_class)
	add_child(stats_manager)
	add_child(skills_manager)

func get_is_enemy_selected() -> bool:
	return targeting_manager.is_enemy_currently_selected()

func get_selected_enemy() -> Enemy:
	return targeting_manager.get_selected_enemy()

# ─── Private Methods ─────────────────────────────────────────────────────────
func _initialize_managers() -> void:
	loot_manager = LootManager.new()
	equipment_manager = EquipmentManager.new()
	targeting_manager = TargetingManager.new()
	input_manager = InputManager.new()

	add_child(loot_manager)
	add_child(equipment_manager)
	add_child(targeting_manager)
	add_child(input_manager)

func connect_global_events() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.level_up.connect(_on_level_up)
	EventBus.stat_allocated.connect(stats_manager.add_stat_point)
	EventBus.stat_deallocated.connect(stats_manager.sub_stat_point)
	EventBus.save_stats_points.connect(stats_manager.save_stats)
	EventBus.cancel_stats_points.connect(stats_manager.cancel_stats)

	# Loot events
	EventBus.lootable_item_added.connect(loot_manager.handle_lootable_item_added)
	EventBus.lootable_item_removed.connect(loot_manager.handle_lootable_item_removed)
	EventBus.selected_lootable_items_picked_up.connect(loot_manager.handle_items_picked_up)
	EventBus.item_dropped_from_inventory.connect(_on_item_dropped_from_inventory)

	# Equipment events
	EventBus.equip_item.connect(_on_equip_item)
	EventBus.item_unequipped.connect(_on_item_unequipped)
	EventBus.potions_unequipped.connect(equipment_manager.unequip_potion)
	EventBus.potions_consumed.connect(equipment_manager.consume_potion)
	EventBus.buy_item.connect(equipment_manager.purchase_item)

	# Targeting events
	EventBus.select_enemy.connect(_on_select_enemy)
	EventBus.unselect_enemy.connect(_on_unselect_enemy)
	EventBus.clear_selection_boxes.connect(targeting_manager.clear_all_selection_boxes)

	# Skills events
	EventBus.skill_upgraded.connect(_on_skill_upgraded)
	EventBus.skill_slot_clicked.connect(_on_skill_slot_clicked)
	EventBus.buff_skill_duration_ended.connect(_on_buff_skill_duration_ended)

func execute_skill(_skill: Skill, _skill_slot: SkillSlot):
	if not _skill.can_cast_skill():
		print("cannot cast the skill")
		_skill_slot.disable_progress_bar()
		return 

	if _skill is BuffSkill:
		stats_manager.add_buff_stat(_skill)
		skills_manager.add_active_skill(_skill)
		return
	if _skill is AttackSkill:
		var _enemy = targeting_manager.selected_enemy
		if not _enemy:
			printerr("No enemy is selected")
			_skill_slot.disable_progress_bar()
			return
			
		stats_manager.consume_mana_on_cast_skill(_skill)
		skills_manager.injecting_the_skill_into_the_scene(_skill, _enemy)
		return

func reset_skill(_skill: Skill, _value: float):
	if _skill is BuffSkill:
		stats_manager.remove_buff_stat(_skill, _value)
		skills_manager.remove_active_skill(_skill)



# ─── Signal Handlers ─────────────────────────────────────────────────────────
func _on_enemy_died(enemy: Enemy) -> void:
	var enemy_lvl: int = enemy.enemy_level if "enemy_level" in enemy else 1
	var enemy_rank = enemy.enemy_rank if "enemy_rank" in enemy else ProgressionManager.EnemyRank.NORMAL
	var xp_reward: int = ProgressionManager.get_enemy_xp_yield(enemy_lvl, enemy_rank, PlayerData.get_player_level())

	if targeting_manager.get_selected_enemy() == enemy:
		targeting_manager.clear_selection(player_ref as Player)

	if xp_reward > 0:
		ProgressionManager.add_player_xp(xp_reward, PlayerData.get_player_level(), level_scaler)

	loot_manager.spawn_enemy_drops(enemy)

func _on_item_dropped_from_inventory(item: DataItem) -> void:
	loot_manager.handle_inventory_item_dropped(item, player_ref.global_position, get_tree())

func _on_equip_item(inventory_slot: InventorySlot) -> void:
	equipment_manager.equip_item_from_slot(inventory_slot, player_ref, stats_manager)

func _on_item_unequipped(item: EquipableItem) -> void:
	equipment_manager.unequip_item(item, player_ref, stats_manager)

func _on_select_enemy(enemy: Enemy) -> void:
	targeting_manager.select_enemy(enemy, player_ref as Player)

func _on_unselect_enemy() -> void:
	targeting_manager.clear_selection(player_ref as Player)

func _on_level_up(_new_level: int) -> void:
	# Update stats manager after level-up
	stats_manager.update_available_points_on_level_up()
	skills_manager.update_player_current_skills_points_on_level_up()

func _on_skill_upgraded(_skill: Skill):
	if _skill is PassiveSkill:
		stats_manager.calculate_passive_skills_stats(_skill)
	else:
		EventBus.add_skill_to_skillsbar.emit(_skill)


func _on_skill_slot_clicked(_skill: Skill, _skill_slot: SkillSlot):
	execute_skill(_skill, _skill_slot)

func _on_buff_skill_duration_ended(_skill: BuffSkill, _value: float):
	reset_skill(_skill, _value)
