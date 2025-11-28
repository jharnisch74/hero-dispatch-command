# res://scripts/game_manager.gd
# Handles mission timeout and chaos system integration
extends Node

# Resources
var money: int = 500
var fame: int = 0

# Collections
var heroes: Array[Hero] = []
var active_missions: Array[Mission] = []
var available_missions: Array[Mission] = []

# Mission generation
var mission_counter: int = 0
var next_mission_spawn_time: float = 5.0
var mission_spawn_timer: float = 0.0

# Chaos System
var chaos_system: ChaosSystem

# Recruitment System
var recruitment_system: RecruitmentSystem

# UI References (set by Main scene)
var hero_list_container: VBoxContainer
var mission_list_container: VBoxContainer
var money_label: Label
var fame_label: Label
var status_label: Label

# Signals
signal money_changed(new_amount: int)
signal fame_changed(new_amount: int)
signal hero_updated(hero: Hero)
signal mission_completed(mission: Mission, result: Dictionary)
signal mission_expired(mission: Mission)
signal heroes_changed()

func _ready() -> void:
	_initialize_chaos_system()
	_initialize_recruitment_system()
	_initialize_starting_heroes()
	_spawn_initial_missions()

func _initialize_chaos_system() -> void:
	chaos_system = ChaosSystem.new(self)
	add_child(chaos_system)
	
	# Connect chaos signals
	chaos_system.chaos_level_changed.connect(_on_chaos_level_changed)
	chaos_system.chaos_threshold_crossed.connect(_on_chaos_threshold_crossed)
	chaos_system.crisis_event_triggered.connect(_on_crisis_event_triggered)

func _initialize_recruitment_system() -> void:
	recruitment_system = RecruitmentSystem.new(self)
	add_child(recruitment_system)

func _process(delta: float) -> void:
	_update_heroes(delta)
	_update_active_missions(delta)
	_update_available_missions_timeout(delta)
	_update_mission_spawning(delta)

func _update_available_missions_timeout(delta: float) -> void:
	"""Check for missions that have expired"""
	var expired_missions = []
	
	for mission in available_missions:
		if mission.update_availability_timer(delta):
			expired_missions.append(mission)
	
	# Handle expired missions
	for mission in expired_missions:
		_expire_mission(mission)

func _expire_mission(mission: Mission) -> void:
	"""Handle mission expiration (timeout)"""
	print("⏰ MISSION EXPIRED: %s in %s" % [mission.mission_name, mission.zone])
	
	# Increase chaos in the zone
	if chaos_system:
		chaos_system.on_mission_expired(mission)
	
	# Remove from available missions
	available_missions.erase(mission)
	
	# Emit signal
	mission_expired.emit(mission)
	
	# Update status
	var zone = mission.zone if mission.get("zone") else "downtown"
	update_status("⏰ Mission EXPIRED: %s - Chaos rising in %s!" % [mission.mission_name, zone.capitalize()])
	
	# Spawn a new mission to replace it
	_generate_new_mission()

func _input(event: InputEvent) -> void:
	# Debug hotkey: Press F9 to force reset all hero availability
	if event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_F9):
		force_reset_all_heroes()
	
	# Debug hotkey: Press F8 to delete save and restart
	if Input.is_key_pressed(KEY_F8):
		delete_save_and_restart()

func force_reset_all_heroes() -> void:
	"""Debug function to force reset all heroes to available state"""
	print("🔧 FORCING RESET OF ALL HEROES")
	for hero in heroes:
		hero.is_on_mission = false
		hero.is_recovering = false
		hero.recovery_time_remaining = 0.0
		hero.current_mission_id = ""
		hero.current_health = hero.max_health
		hero.current_stamina = hero.max_stamina
		print("  ✅ Reset: %s" % hero.hero_name)
	
	# Also clear any stuck mission assignments
	for mission in available_missions:
		mission.assigned_hero_ids.clear()
	
	update_status("🔧 All heroes forcibly reset to available!")

func delete_save_and_restart() -> void:
	"""Debug function to delete save file and restart with fresh data"""
	print("🗑️ DELETING SAVE FILE AND RESTARTING...")
	const SAVE_PATH = "user://hero_dispatch_save.json"
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("  ✅ Save file deleted")
	
	# Clear current data
	heroes.clear()
	available_missions.clear()
	active_missions.clear()
	money = 500
	fame = 0
	mission_counter = 0
	
	# Reset chaos system
	if chaos_system:
		chaos_system.reset()
	
	# Reset recruitment system
	if recruitment_system:
		recruitment_system.reset()
	
	# Reinitialize
	_initialize_starting_heroes()
	_spawn_initial_missions()
	
	# Update UI
	if money_label:
		money_label.text = "💰 Money: $%d" % money
	if fame_label:
		fame_label.text = "⭐ Fame: %d" % fame
	
	update_status("🗑️ Save deleted! Fresh start with 3 heroes!")
	print("  ✅ Game restarted with %d heroes" % heroes.size())

func _initialize_starting_heroes() -> void:
	# Only initialize if we don't already have heroes (fresh start)
	if heroes.size() > 0:
		print("Heroes already loaded (probably from save file)")
		return
	
	# Use recruitment system's starting heroes (3 balanced heroes)
	var starting_heroes = recruitment_system.get_starting_heroes()
	print("Initializing %d starting heroes..." % starting_heroes.size())
	
	for hero_data in starting_heroes:
		var specs_array: Array[Hero.Specialty] = []
		for spec in hero_data.specialties:
			specs_array.append(spec)
		
		var hero = Hero.new(
			"hero_" + str(heroes.size()),
			hero_data.name,
			hero_data.emoji,
			specs_array
		)
		
		# Boost starter heroes (they're all RARE)
		hero.base_strength += 2
		hero.base_speed += 2
		hero.base_intelligence += 2
		
		heroes.append(hero)
		print("  Created hero: %s" % hero.hero_name)

func _spawn_initial_missions() -> void:
	for i in range(3):
		_generate_new_mission()

func _update_heroes(delta: float) -> void:
	for hero in heroes:
		hero.update_recovery(delta)
		hero.regen_stamina(delta)
		hero_updated.emit(hero)

func _update_active_missions(delta: float) -> void:
	var completed_missions = []
	
	for mission in active_missions:
		if mission.update_mission(delta):
			completed_missions.append(mission)
	
	for mission in completed_missions:
		_complete_mission(mission)

func _update_mission_spawning(delta: float) -> void:
	mission_spawn_timer += delta
	
	if mission_spawn_timer >= next_mission_spawn_time:
		mission_spawn_timer = 0.0
		next_mission_spawn_time = randf_range(8.0, 15.0)
		
		if available_missions.size() < 6:
			_generate_new_mission()

func _generate_new_mission() -> void:
	mission_counter += 1
	
	var mission_templates = MissionData.get_mission_templates()
	
	# Weight difficulties based on current fame
	var difficulty_weights = []
	if fame < 50:
		difficulty_weights = [0.5, 0.3, 0.15, 0.05]
	elif fame < 150:
		difficulty_weights = [0.3, 0.4, 0.2, 0.1]
	elif fame < 300:
		difficulty_weights = [0.2, 0.3, 0.35, 0.15]
	else:
		difficulty_weights = [0.1, 0.25, 0.4, 0.25]
	
	var template = mission_templates[randi() % mission_templates.size()]
	var difficulty = _pick_weighted_difficulty(difficulty_weights)
	
	var mission = Mission.new(
		"mission_" + str(mission_counter),
		template.name,
		template.emoji,
		template.description,
		difficulty
	)
	
	# Set specialties
	var specs_array: Array[Hero.Specialty] = []
	for spec in template.specialties:
		specs_array.append(spec)
	mission.preferred_specialties = specs_array
	
	# Set zone (will be used by mission_map)
	mission.zone = template.get("zone", "downtown")
	
	mission.max_heroes = 1 if difficulty == Mission.Difficulty.EASY else (3 if difficulty == Mission.Difficulty.EXTREME else 2)
	
	# Apply chaos effects to the mission
	if chaos_system:
		chaos_system.apply_chaos_to_mission(mission)
	
	available_missions.append(mission)

func _pick_weighted_difficulty(weights: Array) -> Mission.Difficulty:
	var roll = randf()
	var cumulative = 0.0
	
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i as Mission.Difficulty
	
	return Mission.Difficulty.EASY

func assign_hero_to_mission(hero: Hero, mission: Mission) -> bool:
	if not hero.is_available():
		var reason = ""
		if hero.is_on_mission:
			reason = "currently on mission"
		elif hero.is_recovering:
			reason = "recovering"
		elif hero.current_health <= 0:
			reason = "defeated"
		elif hero.current_stamina < 20:
			reason = "exhausted"
		update_status("❌ %s is %s!" % [hero.hero_name, reason])
		return false
	
	# Check if hero is already assigned to ANY mission
	for other_mission in available_missions:
		if other_mission.mission_id != mission.mission_id and hero.hero_id in other_mission.assigned_hero_ids:
			update_status("❌ %s is already assigned to %s!" % [hero.hero_name, other_mission.mission_name])
			return false
	
	if mission.is_active or mission.is_completed or mission.is_expired:
		update_status("❌ Mission already started, completed, or expired!")
		return false
	
	if mission.assign_hero(hero.hero_id):
		update_status("✅ %s assigned to %s" % [hero.hero_name, mission.mission_name])
		return true
	else:
		update_status("❌ Cannot assign more heroes to this mission!")
		return false

func unassign_hero_from_mission(hero: Hero, mission: Mission) -> bool:
	if mission.unassign_hero(hero.hero_id):
		update_status("🔄 %s removed from mission" % hero.hero_name)
		return true
	return false

func start_mission(mission: Mission) -> bool:
	if not mission.can_start():
		update_status("❌ Need at least %d hero(es) assigned!" % mission.min_heroes)
		return false
	
	var assigned_heroes: Array[Hero] = []
	for hero in heroes:
		if hero.hero_id in mission.assigned_hero_ids:
			assigned_heroes.append(hero)
	
	for hero in assigned_heroes:
		hero.use_stamina(30.0)
	
	mission.start_mission(assigned_heroes)
	available_missions.erase(mission)
	active_missions.append(mission)
	
	update_status("🚀 Mission started: %s" % mission.mission_name)
	return true

func _complete_mission(mission: Mission) -> void:
	var result = mission.complete_mission()
	
	# Update chaos system based on mission result
	if chaos_system:
		if result.success:
			chaos_system.on_mission_success(mission)
		else:
			chaos_system.on_mission_failed(mission)
	
	add_money(result.money)
	add_fame(result.fame)
	
	var hero_names = []
	for hero_id in result.hero_ids:
		var hero = get_hero_by_id(hero_id)
		if hero:
			hero_names.append(hero.hero_name)
			hero.is_on_mission = false
			hero.current_mission_id = ""
			hero.add_experience(result.exp)
			
			if randf() < mission.damage_risk:
				var damage = randf_range(10, 30)
				hero.take_damage(damage)
	
	var heroes_text = _format_hero_names(hero_names)
	var story_message = MissionData.get_success_story(
		mission.mission_name,
		heroes_text,
		result.success,
		result.money,
		result.fame
	)
	
	# Add chaos info to story message
	if chaos_system:
		var zone = mission.zone if mission.get("zone") else "downtown"
		var chaos_level = chaos_system.get_chaos_level(zone)
		var chaos_tier = chaos_system.get_chaos_tier(zone)
		
		if result.success:
			story_message += "\n\n✅ %s stabilized: %.0f%% chaos (%s)" % [zone.capitalize(), chaos_level, chaos_tier]
		else:
			story_message += "\n\n🔥 %s destabilized: %.0f%% chaos (%s)" % [zone.capitalize(), chaos_level, chaos_tier]
	
	if status_label:
		status_label.text = story_message
	
	print("=== MISSION COMPLETE ===")
	print(story_message)
	print("=======================")
	
	mission_completed.emit(mission, result)
	active_missions.erase(mission)

func _format_hero_names(hero_names: Array) -> String:
	if hero_names.size() == 1:
		return hero_names[0]
	elif hero_names.size() == 2:
		return hero_names[0] + " and " + hero_names[1]
	else:
		return ", ".join(hero_names.slice(0, -1)) + ", and " + hero_names[-1]

func get_hero_by_id(id: String) -> Hero:
	for hero in heroes:
		if hero.hero_id == id:
			return hero
	return null

func is_hero_assigned_to_mission(hero_id: String) -> Mission:
	"""Returns the mission a hero is assigned to, or null if not assigned"""
	for mission in available_missions:
		if hero_id in mission.assigned_hero_ids:
			return mission
	return null

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)
	if money_label:
		money_label.text = "💰 Money: $%d" % money

func add_fame(amount: int) -> void:
	fame += amount
	fame_changed.emit(fame)
	if fame_label:
		fame_label.text = "⭐ Fame: %d" % fame

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		if money_label:
			money_label.text = "💰 Money: $%d" % money
		return true
	return false

func update_status(text: String) -> void:
	if status_label:
		status_label.text = text

func upgrade_hero_stat(hero: Hero, stat_type: String) -> bool:
	var cost = hero.get_upgrade_cost(stat_type)
	if spend_money(cost):
		if hero.upgrade_stat(stat_type):
			update_status("⬆️ Upgraded %s's %s for $%d" % [hero.hero_name, stat_type, cost])
			hero_updated.emit(hero)
			return true
	else:
		update_status("❌ Not enough money! Need $%d" % cost)
	return false

# Chaos System Signal Handlers
func _on_chaos_level_changed(zone: String, new_level: float) -> void:
	# Optionally update UI or trigger visual effects
	pass

func _on_chaos_threshold_crossed(zone: String, threshold: String) -> void:
	var tier_emoji = ""
	match threshold:
		"LOW":
			tier_emoji = "⚠️"
		"MEDIUM":
			tier_emoji = "🔥"
		"HIGH":
			tier_emoji = "💥"
		"CRITICAL":
			tier_emoji = "🚨"
	
	update_status("%s %s chaos has reached %s level!" % [tier_emoji, zone.capitalize(), threshold])

func _on_crisis_event_triggered(zone: String, event_type: String) -> void:
	var event_name = event_type.replace("_", " ").capitalize()
	update_status("🚨 CRISIS EVENT: %s in %s!" % [event_name, zone.capitalize()])

func get_zone_chaos_info() -> Dictionary:
	"""Get chaos information for all zones"""
	var info = {}
	if chaos_system:
		for zone in ["downtown", "industrial", "residential", "park", "waterfront"]:
			info[zone] = {
				"level": chaos_system.get_chaos_level(zone),
				"tier": chaos_system.get_chaos_tier(zone),
				"color": chaos_system.get_chaos_color(zone),
				"effects": chaos_system.get_chaos_effects(zone)
			}
	return info
