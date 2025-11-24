# res://scripts/save_manager.gd
# New file - handles all save/load operations

extends Node

const SAVE_PATH = "user://hero_dispatch_save.json"
const AUTO_SAVE_INTERVAL = 30.0  # Auto-save every 30 seconds

var auto_save_timer: float = 0.0
var game_manager: Node = null

func _ready() -> void:
	# This will be called when added to the scene tree
	pass

func _process(delta: float) -> void:
	if game_manager:
		auto_save_timer += delta
		if auto_save_timer >= AUTO_SAVE_INTERVAL:
			auto_save_timer = 0.0
			save_game()

func set_game_manager(gm: Node) -> void:
	game_manager = gm

func save_game() -> bool:
	if not game_manager:
		push_error("SaveManager: No game_manager reference set!")
		return false
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"money": game_manager.money,
		"fame": game_manager.fame,
		"mission_counter": game_manager.mission_counter,
		"heroes": _serialize_heroes(),
		"available_missions": _serialize_missions(game_manager.available_missions),
		"active_missions": _serialize_missions(game_manager.active_missions)
	}
	
	var json_string = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("SaveManager: Failed to open save file for writing!")
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("Game saved successfully at: ", SAVE_PATH)
	# Don't update status label - let mission results show instead
	
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: No save file found, starting fresh game")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading!")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("SaveManager: Failed to parse save file JSON!")
		return false
	
	var save_data = json.data
	
	if not game_manager:
		push_error("SaveManager: No game_manager reference set!")
		return false
	
	# Load basic data
	game_manager.money = save_data.get("money", 500)
	game_manager.fame = save_data.get("fame", 0)
	game_manager.mission_counter = save_data.get("mission_counter", 0)
	
	# Load heroes
	_deserialize_heroes(save_data.get("heroes", []))
	
	# Load missions
	game_manager.available_missions = _deserialize_missions(save_data.get("available_missions", []))
	game_manager.active_missions = _deserialize_missions(save_data.get("active_missions", []))
	
	# Update UI
	if game_manager.money_label:
		game_manager.money_label.text = "💰 Money: $%d" % game_manager.money
	if game_manager.fame_label:
		game_manager.fame_label.text = "⭐ Fame: %d" % game_manager.fame
	if game_manager.status_label:
		game_manager.status_label.text = "✅ Game Loaded Successfully!"
	
	print("Game loaded successfully!")
	return true

func _serialize_heroes() -> Array:
	var heroes_data = []
	
	for hero in game_manager.heroes:
		var hero_dict = {
			"hero_id": hero.hero_id,
			"hero_name": hero.hero_name,
			"hero_emoji": hero.hero_emoji,
			"level": hero.level,
			"experience": hero.experience,
			"exp_to_next_level": hero.exp_to_next_level,
			"base_strength": hero.base_strength,
			"base_speed": hero.base_speed,
			"base_intelligence": hero.base_intelligence,
			"strength_modifier": hero.strength_modifier,
			"speed_modifier": hero.speed_modifier,
			"intelligence_modifier": hero.intelligence_modifier,
			"current_health": hero.current_health,
			"max_health": hero.max_health,
			"current_stamina": hero.current_stamina,
			"max_stamina": hero.max_stamina,
			"is_on_mission": hero.is_on_mission,
			"is_recovering": hero.is_recovering,
			"recovery_time_remaining": hero.recovery_time_remaining,
			"current_mission_id": hero.current_mission_id,
			"specialties": _serialize_specialties(hero.specialties),
			"upgrade_cost_multiplier": hero.upgrade_cost_multiplier
		}
		heroes_data.append(hero_dict)
	
	return heroes_data

func _deserialize_heroes(heroes_data: Array) -> void:
	game_manager.heroes.clear()
	
	for hero_dict in heroes_data:
		var specialties = _deserialize_specialties(hero_dict.get("specialties", []))
		
		var hero = Hero.new(
			hero_dict.get("hero_id", ""),
			hero_dict.get("hero_name", "Unknown"),
			hero_dict.get("hero_emoji", "❓"),
			specialties
		)
		
		# Restore stats
		hero.level = hero_dict.get("level", 1)
		hero.experience = hero_dict.get("experience", 0)
		hero.exp_to_next_level = hero_dict.get("exp_to_next_level", 100)
		hero.base_strength = hero_dict.get("base_strength", 5)
		hero.base_speed = hero_dict.get("base_speed", 5)
		hero.base_intelligence = hero_dict.get("base_intelligence", 5)
		hero.strength_modifier = hero_dict.get("strength_modifier", 0)
		hero.speed_modifier = hero_dict.get("speed_modifier", 0)
		hero.intelligence_modifier = hero_dict.get("intelligence_modifier", 0)
		hero.current_health = hero_dict.get("current_health", 100.0)
		hero.max_health = hero_dict.get("max_health", 100.0)
		hero.current_stamina = hero_dict.get("current_stamina", 100.0)
		hero.max_stamina = hero_dict.get("max_stamina", 100.0)
		hero.is_on_mission = hero_dict.get("is_on_mission", false)
		hero.is_recovering = hero_dict.get("is_recovering", false)
		hero.recovery_time_remaining = hero_dict.get("recovery_time_remaining", 0.0)
		hero.current_mission_id = hero_dict.get("current_mission_id", "")
		hero.upgrade_cost_multiplier = hero_dict.get("upgrade_cost_multiplier", 1.0)
		
		game_manager.heroes.append(hero)

func _serialize_missions(missions: Array) -> Array:
	var missions_data = []
	
	for mission in missions:
		var mission_dict = {
			"mission_id": mission.mission_id,
			"mission_name": mission.mission_name,
			"mission_emoji": mission.mission_emoji,
			"description": mission.description,
			"difficulty": mission.difficulty,
			"required_power": mission.required_power,
			"preferred_specialties": _serialize_specialties(mission.preferred_specialties),
			"min_heroes": mission.min_heroes,
			"max_heroes": mission.max_heroes,
			"money_reward": mission.money_reward,
			"fame_reward": mission.fame_reward,
			"exp_reward": mission.exp_reward,
			"base_duration": mission.base_duration,
			"time_remaining": mission.time_remaining,
			"is_active": mission.is_active,
			"is_completed": mission.is_completed,
			"assigned_hero_ids": mission.assigned_hero_ids,
			"success_chance": mission.success_chance,
			"damage_risk": mission.damage_risk
		}
		missions_data.append(mission_dict)
	
	return missions_data

func _deserialize_missions(missions_data: Array) -> Array[Mission]:
	var missions: Array[Mission] = []
	
	for mission_dict in missions_data:
		var mission = Mission.new(
			mission_dict.get("mission_id", ""),
			mission_dict.get("mission_name", "Unknown"),
			mission_dict.get("mission_emoji", "❓"),
			mission_dict.get("description", ""),
			mission_dict.get("difficulty", Mission.Difficulty.EASY)
		)
		
		# Restore mission data
		mission.required_power = mission_dict.get("required_power", 15)
		mission.preferred_specialties = _deserialize_specialties(mission_dict.get("preferred_specialties", []))
		mission.min_heroes = mission_dict.get("min_heroes", 1)
		mission.max_heroes = mission_dict.get("max_heroes", 3)
		mission.money_reward = mission_dict.get("money_reward", 50)
		mission.fame_reward = mission_dict.get("fame_reward", 5)
		mission.exp_reward = mission_dict.get("exp_reward", 20)
		mission.base_duration = mission_dict.get("base_duration", 10.0)
		mission.time_remaining = mission_dict.get("time_remaining", 0.0)
		mission.is_active = mission_dict.get("is_active", false)
		mission.is_completed = mission_dict.get("is_completed", false)
		
		# Convert assigned_hero_ids to typed array
		var hero_ids: Array[String] = []
		for id in mission_dict.get("assigned_hero_ids", []):
			hero_ids.append(id)
		mission.assigned_hero_ids = hero_ids
		
		mission.success_chance = mission_dict.get("success_chance", 0.0)
		mission.damage_risk = mission_dict.get("damage_risk", 0.1)
		
		missions.append(mission)
	
	return missions

func _serialize_specialties(specialties: Array) -> Array:
	var specs_int = []
	for spec in specialties:
		specs_int.append(spec as int)
	return specs_int

func _deserialize_specialties(specs_int: Array) -> Array[Hero.Specialty]:
	var specialties: Array[Hero.Specialty] = []
	for spec_value in specs_int:
		specialties.append(spec_value as Hero.Specialty)
	return specialties

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted")
		if game_manager and game_manager.status_label:
			game_manager.status_label.text = "🗑️ Save Deleted"
