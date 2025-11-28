# res://scripts/chaos_system.gd
extends Node
class_name ChaosSystem

# Chaos state for each zone
var zone_chaos: Dictionary = {
	"downtown": 0.0,
	"industrial": 0.0,
	"residential": 0.0,
	"park": 0.0,
	"waterfront": 0.0
}

# Chaos thresholds
const CHAOS_LOW = 25.0
const CHAOS_MEDIUM = 50.0
const CHAOS_HIGH = 75.0
const CHAOS_CRITICAL = 90.0

# Chaos effects
const CHAOS_DECAY_RATE = 1.5  # Points per minute when no active missions in zone
const CHAOS_MISSION_FAILURE_INCREASE = 15.0
const CHAOS_MISSION_SUCCESS_DECREASE = 8.0
const CHAOS_MISSION_EXPIRED_INCREASE = 12.0  # When mission times out

# Game manager reference
var game_manager: Node

signal chaos_level_changed(zone: String, new_level: float)
signal chaos_threshold_crossed(zone: String, threshold: String)
signal crisis_event_triggered(zone: String, event_type: String)

func _init(gm: Node = null):
	game_manager = gm

func _process(delta: float) -> void:
	_decay_chaos_smart(delta)

func _decay_chaos_smart(delta: float) -> void:
	"""Only decay chaos in zones with NO active missions"""
	if not game_manager:
		return
	
	# Count active missions per zone
	var active_missions_by_zone = {}
	for zone in zone_chaos.keys():
		active_missions_by_zone[zone] = 0
	
	for mission in game_manager.active_missions:
		var zone = mission.zone if mission.get("zone") else "downtown"
		active_missions_by_zone[zone] += 1
	
	# Only decay zones with no active missions
	var decay_amount = (CHAOS_DECAY_RATE / 60.0) * delta
	
	for zone in zone_chaos.keys():
		if active_missions_by_zone[zone] == 0 and zone_chaos[zone] > 0:
			var old_level = zone_chaos[zone]
			zone_chaos[zone] = max(0.0, zone_chaos[zone] - decay_amount)
			
			if old_level != zone_chaos[zone]:
				chaos_level_changed.emit(zone, zone_chaos[zone])
				_check_threshold_crossing(zone, old_level, zone_chaos[zone])

func on_mission_expired(mission: Mission) -> void:
	"""Called when a mission expires (times out) - increases chaos"""
	var zone = mission.zone if mission.get("zone") else "downtown"
	
	var old_level = zone_chaos[zone]
	var increase = CHAOS_MISSION_EXPIRED_INCREASE
	
	# Scale increase by difficulty
	match mission.difficulty:
		Mission.Difficulty.EASY:
			increase *= 0.7
		Mission.Difficulty.MEDIUM:
			increase *= 1.0
		Mission.Difficulty.HARD:
			increase *= 1.4
		Mission.Difficulty.EXTREME:
			increase *= 1.8
	
	zone_chaos[zone] = min(100.0, zone_chaos[zone] + increase)
	
	print("⏰ MISSION EXPIRED - CHAOS INCREASE in %s: %.1f -> %.1f (+%.1f)" % [zone, old_level, zone_chaos[zone], increase])
	
	chaos_level_changed.emit(zone, zone_chaos[zone])
	_check_threshold_crossing(zone, old_level, zone_chaos[zone])
	
	# Check for crisis events
	if zone_chaos[zone] >= CHAOS_CRITICAL:
		_trigger_crisis_event(zone)

func on_mission_failed(mission: Mission) -> void:
	"""Called when a mission fails - increases chaos in that zone"""
	var zone = mission.zone if mission.get("zone") else "downtown"
	
	var old_level = zone_chaos[zone]
	var increase = CHAOS_MISSION_FAILURE_INCREASE
	
	# Scale increase by difficulty
	match mission.difficulty:
		Mission.Difficulty.EASY:
			increase *= 0.8
		Mission.Difficulty.MEDIUM:
			increase *= 1.0
		Mission.Difficulty.HARD:
			increase *= 1.3
		Mission.Difficulty.EXTREME:
			increase *= 1.6
	
	zone_chaos[zone] = min(100.0, zone_chaos[zone] + increase)
	
	print("🔥 MISSION FAILED - CHAOS INCREASE in %s: %.1f -> %.1f (+%.1f)" % [zone, old_level, zone_chaos[zone], increase])
	
	chaos_level_changed.emit(zone, zone_chaos[zone])
	_check_threshold_crossing(zone, old_level, zone_chaos[zone])
	
	# Check for crisis events
	if zone_chaos[zone] >= CHAOS_CRITICAL:
		_trigger_crisis_event(zone)

func on_mission_success(mission: Mission) -> void:
	"""Called when a mission succeeds - decreases chaos in that zone"""
	var zone = mission.zone if mission.get("zone") else "downtown"
	
	var old_level = zone_chaos[zone]
	var decrease = CHAOS_MISSION_SUCCESS_DECREASE
	
	# Scale decrease by difficulty (harder missions reduce more chaos)
	match mission.difficulty:
		Mission.Difficulty.EASY:
			decrease *= 0.8
		Mission.Difficulty.MEDIUM:
			decrease *= 1.0
		Mission.Difficulty.HARD:
			decrease *= 1.2
		Mission.Difficulty.EXTREME:
			decrease *= 1.5
	
	zone_chaos[zone] = max(0.0, zone_chaos[zone] - decrease)
	
	if old_level != zone_chaos[zone]:
		print("✅ MISSION SUCCESS - CHAOS DECREASE in %s: %.1f -> %.1f (-%.1f)" % [zone, old_level, zone_chaos[zone], decrease])
		chaos_level_changed.emit(zone, zone_chaos[zone])
		_check_threshold_crossing(zone, old_level, zone_chaos[zone])

func _check_threshold_crossing(zone: String, old_level: float, new_level: float) -> void:
	"""Check if chaos crossed a threshold and emit appropriate signals"""
	var thresholds = [
		{"level": CHAOS_CRITICAL, "name": "CRITICAL"},
		{"level": CHAOS_HIGH, "name": "HIGH"},
		{"level": CHAOS_MEDIUM, "name": "MEDIUM"},
		{"level": CHAOS_LOW, "name": "LOW"}
	]
	
	for threshold in thresholds:
		var level = threshold.level
		var name = threshold.name
		
		# Crossing upward
		if old_level < level and new_level >= level:
			print("⚠️ %s chaos reached %s threshold!" % [zone.to_upper(), name])
			chaos_threshold_crossed.emit(zone, name)
			
			if name == "CRITICAL":
				_trigger_crisis_event(zone)
		
		# Crossing downward
		elif old_level >= level and new_level < level:
			print("✅ %s chaos dropped below %s threshold" % [zone.to_upper(), name])

func _trigger_crisis_event(zone: String) -> void:
	"""Trigger a special crisis event when chaos is critical"""
	var event_types = ["riot", "villain_takeover", "infrastructure_collapse", "mass_panic"]
	var event_type = event_types[randi() % event_types.size()]
	
	print("🚨 CRISIS EVENT in %s: %s" % [zone.to_upper(), event_type])
	crisis_event_triggered.emit(zone, event_type)
	
	# Create a crisis mission
	if game_manager:
		_create_crisis_mission(zone, event_type)

func _create_crisis_mission(zone: String, event_type: String) -> void:
	"""Create an urgent crisis mission"""
	if not game_manager:
		return
	
	var mission_data = _get_crisis_mission_data(event_type, zone)
	
	game_manager.mission_counter += 1
	var mission = Mission.new(
		"crisis_mission_" + str(game_manager.mission_counter),
		mission_data.name,
		mission_data.emoji,
		mission_data.description,
		Mission.Difficulty.EXTREME
	)
	
	mission.zone = zone
	mission.required_power = 100
	mission.min_heroes = 2
	mission.max_heroes = 3
	mission.money_reward = 1500
	mission.fame_reward = 150
	mission.exp_reward = 300
	mission.base_duration = 45.0
	mission.damage_risk = 0.7
	mission.availability_timeout = 30.0  # Crisis missions expire VERY quickly!
	
	var specs_array: Array[Hero.Specialty] = []
	for spec in mission_data.specialties:
		specs_array.append(spec)
	mission.preferred_specialties = specs_array
	
	game_manager.available_missions.insert(0, mission)  # Add at front
	
	if game_manager.status_label:
		game_manager.status_label.text = "🚨 CRISIS in %s: %s!" % [zone.to_upper(), mission_data.name]

func _get_crisis_mission_data(event_type: String, zone: String) -> Dictionary:
	"""Get mission data for crisis events"""
	var data = {
		"name": "",
		"emoji": "🚨",
		"description": "",
		"specialties": []
	}
	
	match event_type:
		"riot":
			data.name = "Suppress Riot in " + zone.capitalize()
			data.description = "Mass chaos has erupted! Civilians are in danger and property is being destroyed. Restore order immediately!"
			data.specialties = [Hero.Specialty.COMBAT, Hero.Specialty.RESCUE]
		
		"villain_takeover":
			data.name = "Stop Villain Takeover of " + zone.capitalize()
			data.description = "A powerful villain has seized control of the area! Multiple hostages reported. This is your highest priority!"
			data.specialties = [Hero.Specialty.COMBAT, Hero.Specialty.INVESTIGATION]
		
		"infrastructure_collapse":
			data.name = "Emergency: Infrastructure Failure in " + zone.capitalize()
			data.description = "Critical systems are failing! Power outages, water main breaks, and building collapses. Lives are at stake!"
			data.specialties = [Hero.Specialty.TECH, Hero.Specialty.RESCUE]
		
		"mass_panic":
			data.name = "Contain Mass Panic in " + zone.capitalize()
			data.description = "Fear has gripped the population! Stampedes and accidents are occurring. Calm the situation before more people are hurt!"
			data.specialties = [Hero.Specialty.RESCUE, Hero.Specialty.SPEED]
	
	return data

func get_chaos_level(zone: String) -> float:
	"""Get current chaos level for a zone"""
	return zone_chaos.get(zone, 0.0)

func get_chaos_tier(zone: String) -> String:
	"""Get the chaos tier name for a zone"""
	var level = get_chaos_level(zone)
	
	if level >= CHAOS_CRITICAL:
		return "CRITICAL"
	elif level >= CHAOS_HIGH:
		return "HIGH"
	elif level >= CHAOS_MEDIUM:
		return "MEDIUM"
	elif level >= CHAOS_LOW:
		return "LOW"
	else:
		return "STABLE"

func get_chaos_color(zone: String) -> Color:
	"""Get the color representing chaos level"""
	var level = get_chaos_level(zone)
	
	if level >= CHAOS_CRITICAL:
		return Color("#ff0000")  # Red
	elif level >= CHAOS_HIGH:
		return Color("#ff6b00")  # Orange
	elif level >= CHAOS_MEDIUM:
		return Color("#ffaa00")  # Yellow-Orange
	elif level >= CHAOS_LOW:
		return Color("#ffdd00")  # Yellow
	else:
		return Color("#ffffff")  # White

func get_chaos_effects(zone: String) -> Dictionary:
	"""Get the current effects of chaos in a zone"""
	var level = get_chaos_level(zone)
	var effects = {
		"reward_multiplier": 1.0,
		"difficulty_increase": 0,
		"spawn_rate_multiplier": 1.0,
		"description": ""
	}
	
	if level >= CHAOS_CRITICAL:
		effects.reward_multiplier = 0.5
		effects.difficulty_increase = 2
		effects.spawn_rate_multiplier = 2.0
		effects.description = "CRITICAL: Zone in chaos! 50% rewards, missions much harder, frequent incidents!"
	elif level >= CHAOS_HIGH:
		effects.reward_multiplier = 0.7
		effects.difficulty_increase = 1
		effects.spawn_rate_multiplier = 1.5
		effects.description = "HIGH: Dangerous zone! 30% reward penalty, harder missions, more incidents."
	elif level >= CHAOS_MEDIUM:
		effects.reward_multiplier = 0.85
		effects.difficulty_increase = 0
		effects.spawn_rate_multiplier = 1.2
		effects.description = "MEDIUM: Unstable zone. 15% reward penalty, more mission activity."
	elif level >= CHAOS_LOW:
		effects.reward_multiplier = 0.95
		effects.difficulty_increase = 0
		effects.spawn_rate_multiplier = 1.0
		effects.description = "LOW: Minor unrest. 5% reward penalty."
	else:
		effects.description = "STABLE: Normal conditions."
	
	return effects

func apply_chaos_to_mission(mission: Mission) -> void:
	"""Modify a mission based on the chaos level of its zone"""
	var zone = mission.zone if mission.get("zone") else "downtown"
	var effects = get_chaos_effects(zone)
	
	# Apply reward multiplier
	mission.money_reward = int(mission.money_reward * effects.reward_multiplier)
	mission.fame_reward = int(mission.fame_reward * effects.reward_multiplier)
	
	# Increase difficulty if needed
	if effects.difficulty_increase > 0:
		mission.required_power += 15 * effects.difficulty_increase
		mission.damage_risk += 0.1 * effects.difficulty_increase

func get_zone_status_text(zone: String) -> String:
	"""Get status text for a zone"""
	var level = get_chaos_level(zone)
	var tier = get_chaos_tier(zone)
	return "%s: %.0f%% Chaos (%s)" % [zone.capitalize(), level, tier]

func serialize() -> Dictionary:
	"""Serialize chaos system state for saving"""
	return {
		"zone_chaos": zone_chaos.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	"""Deserialize chaos system state from save data"""
	if data.has("zone_chaos"):
		zone_chaos = data.zone_chaos.duplicate()

func reset() -> void:
	"""Reset all chaos levels to 0"""
	for zone in zone_chaos.keys():
		zone_chaos[zone] = 0.0
	print("ChaosSystem: All zones reset to 0% chaos")
