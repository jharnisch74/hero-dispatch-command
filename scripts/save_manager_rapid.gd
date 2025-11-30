# res://scripts/save_manager_rapid.gd
extends Node

const SAVE_PATH = "user://hero_dispatch_save_rapid.json"
const AUTO_SAVE_INTERVAL = 60.0

var auto_save_timer: float = 0.0
var game_manager: Node = null

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
		push_error("SaveManager: No game_manager reference!")
		return false
	
	var save_data = {
		"version": "3.0",
		"timestamp": Time.get_unix_time_from_system(),
		"money": game_manager.money,
		"fame": game_manager.fame,
		"heroes": _serialize_heroes(),
		"chaos_system": game_manager.chaos_system.serialize() if game_manager.chaos_system else {},
		"recruitment_system": game_manager.recruitment_system.serialize() if game_manager.recruitment_system else {},
		"rapid_manager": game_manager.rapid_manager.serialize() if game_manager.rapid_manager else {}
	}
	
	var json_string = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("SaveManager: Failed to open save file!")
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("Game saved successfully")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: No save file found")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file!")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("SaveManager: Failed to parse save file!")
		return false
	
	var save_data = json.data
	
	if not game_manager:
		push_error("SaveManager: No game_manager reference!")
		return false
	
	# Load basic data
	game_manager.money = save_data.get("money", 500)
	game_manager.fame = save_data.get("fame", 0)
	
	# Load heroes
	_deserialize_heroes(save_data.get("heroes", []))
	
	# Load chaos system
	if save_data.has("chaos_system") and game_manager.chaos_system:
		game_manager.chaos_system.deserialize(save_data.chaos_system)
	
	# Load recruitment system
	if save_data.has("recruitment_system") and game_manager.recruitment_system:
		game_manager.recruitment_system.deserialize(save_data.recruitment_system)
	
	# Load rapid manager (after it's created)
	await get_tree().process_frame
	await get_tree().process_frame
	
	if save_data.has("rapid_manager") and game_manager.rapid_manager:
		game_manager.rapid_manager.deserialize(save_data.rapid_manager)
	
	# Update UI
	if game_manager.money_label:
		game_manager.money_label.text = "💰 Money: $%d" % game_manager.money
	if game_manager.fame_label:
		game_manager.fame_label.text = "⭐ Fame: %d" % game_manager.fame
	
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
