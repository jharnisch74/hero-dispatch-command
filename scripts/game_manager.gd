# res://scripts/game_manager.gd
# Handles mission timeout and chaos system integration with DAY SYSTEM
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

# Systems
var chaos_system: ChaosSystem
var recruitment_system: RecruitmentSystem
var day_manager: DayManager

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
signal day_started(day_number: int)
signal day_ended(day_number: int)

func _ready() -> void:
	_initialize_chaos_system()
	_initialize_recruitment_system()
	_initialize_day_manager()
	_initialize_starting_heroes()
	# Don't spawn initial missions - day system will handle it

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

func _initialize_day_manager() -> void:
	day_manager = DayManager.new(self)
	add_child(day_manager)
	
	# Connect day signals
	day_manager.day_started.connect(_on_day_started)
	day_manager.day_ended.connect(_on_day_ended)
	day_manager.zone_selected.connect(_on_zone_selected)
	day_manager.passive_chaos_increased.connect(_on_passive_chaos_increased)

func _process(delta: float) -> void:
	_update_heroes(delta)
	_update_active_missions(delta)
	# No more auto-spawning missions or timeouts - day system handles it

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

# DAY SYSTEM INTEGRATION
func start_new_day(zone_name: String) -> void:
	"""Called when player selects a zone to start the day"""
	day_manager.start_day(zone_name)

func end_current_day() -> void:
	"""Called when player ends the day"""
	day_manager.end_day()

func _on_day_started(day_number: int) -> void:
	"""Called when a new day starts"""
	print("🌅 Day %d started!" % day_number)
	day_started.emit(day_number)
	
	# Update UI
	if status_label:
		status_label.text = "🌅 Day %d - Focus Zone: %s" % [day_number, day_manager.active_zone.capitalize()]

func _on_day_ended(day_number: int) -> void:
	"""Called when a day ends"""
	print("🌙 Day %d ended!" % day_number)
	day_ended.emit(day_number)

func _on_zone_selected(zone_name: String) -> void:
	"""Called when player selects a zone"""
	print("📍 Zone selected: %s" % zone_name)

func _on_passive_chaos_increased(zone_name: String, amount: float) -> void:
	"""Called when a neglected zone's chaos increases"""
	print("⚠️ %s chaos increased by %.1f (passive)" % [zone_name, amount])

func _complete_mission(mission: Mission) -> void:
	var result = mission.complete_mission()
	
	# Update chaos system based on mission result
	if chaos_system:
		if result.success:
			chaos_system.on_mission_success(mission)
		else:
			chaos_system.on_mission_failed(mission)
	
	# Update day manager
	if day_manager:
		day_manager.on_mission_completed(mission)
	
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
	
	# Add day progress
	if day_manager and day_manager.day_in_progress:
		var progress = day_manager.get_day_progress()
		story_message += "\n\n📊 Day Progress: %d/%d missions" % [progress.missions_completed, progress.missions_total]
	
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
