class_name SkillsDatabaseLoader
extends Node

const JSON_FILE_PATH = "res://data/skills_data.json"

var loaded_skills: Dictionary = {}

func _init() -> void:
	load_skills_from_json(JSON_FILE_PATH)

func load_skills_from_json(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_error("Skill JSON file not found at: " + file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return
	
	var root_data = json.get_data()
	if not root_data.has("skills"):
		push_error("Invalid JSON structure: Missing 'skills' root key.")
		return
	
	var skills_by_class = root_data["skills"]
	
	# دور على كل كلاس (Tank, Warrior, Mage, Archer)
	for class_name_str in skills_by_class.keys():
		loaded_skills[class_name_str] = {
			"attack": [] as Array[AttackSkill],
			"buff": [] as Array[BuffSkill],
			"passive": [] as Array[PassiveSkill]
		}
		
		var class_data = skills_by_class[class_name_str]
		
		# 1. قراءة الـ Attack Skills
		if class_data.has("attack"):
			for dict_data in class_data["attack"]:
				var skill_res = _parse_attack_skill(dict_data)
				loaded_skills[class_name_str]["attack"].append(skill_res)
		
		# 2. قراءة الـ Buff Skills
		if class_data.has("buff"):
			for dict_data in class_data["buff"]:
				var skill_res = _parse_buff_skill(dict_data)
				loaded_skills[class_name_str]["buff"].append(skill_res)
		
		# 3. قراءة الـ Passive Skills
		if class_data.has("passive"):
			for dict_data in class_data["passive"]:
				var skill_res = _parse_passive_skill(dict_data)
				loaded_skills[class_name_str]["passive"].append(skill_res)
				
	print("All skills loaded successfully into database!")

func _populate_base_skill(skill_res: Skill, data: Dictionary) -> void:
	skill_res.skill_id = data.get("skill_id", "")
	skill_res.skill_name = data.get("skill_name", "")
	skill_res.description = data.get("description", "")
	skill_res.mp_cost = data.get("mp_cost", 0)
	skill_res.cast_time = data.get("cast_time", 0.0)
	skill_res.cooldown = data.get("cooldown", 0.0)
	skill_res.level = data.get("level", 1)
	skill_res.max_level = data.get("max_level", 1)
	skill_res.required_player_level = data.get("required_player_level", 1)
	skill_res.skill_points_cost = data.get("skill_points_cost", 1)
	
	# تحميل الأيقونة أوتوماتيكيا من icon_path اللي فـ JSON
	var icon_path = data.get("icon_path", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		skill_res.skill_icon = load(icon_path) as Texture2D
	else:
		if icon_path != "":
			push_warning("Icon path not found or invalid: " + icon_path)

func _parse_attack_skill(data: Dictionary) -> AttackSkill:
	var skill = AttackSkill.new()
	_populate_base_skill(skill, data)
	
	# تحديد Target Type (Enemy / AoE)
	var target_str = data.get("skill_target_type", "enemy")
	if target_str == "aoe":
		skill.skill_target_type = AttackSkill.TargetType.aoe
	else:
		skill.skill_target_type = AttackSkill.TargetType.enemy
		
	skill.skill_range = data.get("skill_range", 1.0)
	skill.damage = data.get("damage", 0.0)
	skill.cc_duration = data.get("cc_duration", 0.0)
	
	# تحويل Crowd Control Enum
	var cc_str = data.get("cc_effect", "none")
	skill.cc_effect = _string_to_cc_enum(cc_str)
	
	return skill

func _parse_buff_skill(data: Dictionary) -> BuffSkill:
	var skill = BuffSkill.new()
	_populate_base_skill(skill, data)
	
	skill.value = data.get("value", 0.0)
	skill.duration = data.get("duration", 0.0)
	skill.is_percentage = data.get("is_percentage", false)
	
	var buff_str = data.get("buff_type", "none")
	skill.buff_type = _string_to_buff_enum(buff_str)
	
	return skill

func _parse_passive_skill(data: Dictionary) -> PassiveSkill:
	var skill = PassiveSkill.new()
	_populate_base_skill(skill, data)
	
	skill.bonus_value = data.get("bonus_value", 0.0)
	skill.is_percentage = data.get("is_percentage", false)
	
	var stat_str = data.get("stat_type", "max_hp")
	skill.stat_type = _string_to_passive_enum(stat_str)
	
	return skill

func _string_to_cc_enum(cc_name: String) -> AttackSkill.CrowdControl:
	match cc_name:
		"stun": return AttackSkill.CrowdControl.stun
		"silence": return AttackSkill.CrowdControl.silence
		"bind": return AttackSkill.CrowdControl.bind
		"bleeding": return AttackSkill.CrowdControl.bleeding
		"burn": return AttackSkill.CrowdControl.burn
		"blind": return AttackSkill.CrowdControl.blind
		"slow": return AttackSkill.CrowdControl.slow
		_: return AttackSkill.CrowdControl.none

func _string_to_buff_enum(buff_name: String) -> BuffSkill.BuffType:
	match buff_name:
		"attack_power": return BuffSkill.BuffType.attack_power
		"critical_damage": return BuffSkill.BuffType.critical_damage
		"attack_speed": return BuffSkill.BuffType.attack_speed
		"casting_speed": return BuffSkill.BuffType.casting_speed
		"physical_defence": return BuffSkill.BuffType.physical_defence
		"magical_resistance": return BuffSkill.BuffType.magical_resistance
		"max_hp": return BuffSkill.BuffType.max_hp
		"max_mp": return BuffSkill.BuffType.max_mp
		"regeneration": return BuffSkill.BuffType.regeneration
		"absorption": return BuffSkill.BuffType.absorption
		"movement_speed": return BuffSkill.BuffType.movement_speed
		"accuracy": return BuffSkill.BuffType.accuracy
		"evasion": return BuffSkill.BuffType.evasion
		_: return BuffSkill.BuffType.none

func _string_to_passive_enum(stat_name: String) -> PassiveSkill.PassiveStatType:
	match stat_name:
		"max_hp": return PassiveSkill.PassiveStatType.max_hp
		"max_mp": return PassiveSkill.PassiveStatType.max_mp
		"attack_power": return PassiveSkill.PassiveStatType.attack_power
		"physical_defence": return PassiveSkill.PassiveStatType.physical_defence
		"magical_resistance": return PassiveSkill.PassiveStatType.magical_resistance
		"movement_speed": return PassiveSkill.PassiveStatType.movement_speed
		"critical_damage": return PassiveSkill.PassiveStatType.critical_damage
		_: return PassiveSkill.PassiveStatType.max_hp