# res://scripts/rapid_response_manager.gd
# Addictive swipe-based mission management system
extends Node
class_name RapidResponseManager

signal mission_accepted(mission: Mission)
signal mission_declined(mission: Mission)
signal hero_energy_depleted(hero: Hero)
signal streak_increased(new_streak: int)
signal streak_broken()

var game_manager: Node

# Mission Queue
var mission_queue: Array[Mission] = []
const QUEUE_SIZE = 5
var missions_generated: int = 0

# Zone filtering
var current_zone_filter: String = "all"  # "all" or specific zone name
var filtered_queue: Array[Mission] = []  # Missions matching current filter

# Active Missions (auto-dispatch)
var active_slots: Array[Dictionary] = []  # {mission: Mission, hero: Hero, time_remaining: float}
const MAX_ACTIVE_SLOTS = 3

# Streak System
var current_streak: int = 0
var best_streak: int = 0
const STREAK_BONUS_THRESHOLD = 5

# Hero Energy System
var hero_energy: Dictionary = {}  # {hero_id: energy_percent}
const ENERGY_DRAIN_PER_MISSION = 25.0
const ENERGY_REGEN_PER_SECOND = 2.0

# Stats
var missions_completed_total: int = 0
var missions_declined_total: int = 0
var total_chaos_prevented: float = 0.0

func _init(gm: Node):
	game_manager = gm
	_initialize_hero_energy()

func _ready() -> void:
	_fill_mission_queue()

func _process(delta: float) -> void:
	_update_active_missions(delta)
	_regenerate_hero_energy(delta)

func _initialize_hero_energy() -> void:
	"""Set all heroes to full energy"""
	if not game_manager:
		return
	
	for hero in game_manager.heroes:
		hero_energy[hero.hero_id] = 100.0

func _fill_mission_queue() -> void:
	"""Keep the mission queue filled"""
	while mission_queue.size() < QUEUE_SIZE:
		var mission = _generate_quick_mission()
		if mission:
			mission_queue.append(mission)

func _ensure_zone_missions(zone: String) -> void:
	"""Make sure there are missions for a specific zone in the queue"""
	var zone_missions = 0
	for mission in mission_queue:
		if mission.zone == zone:
			zone_missions += 1
	
	# Ensure at least 2 missions for the selected zone
	while zone_missions < 2 and mission_queue.size() < QUEUE_SIZE:
		var mission = _generate_quick_mission_for_zone(zone)
		if mission:
			mission_queue.append(mission)
			zone_missions += 1

func _generate_quick_mission_for_zone(zone: String) -> Mission:
	"""Generate a mission specifically for a zone"""
	var mission = _generate_quick_mission()
	if mission:
		mission.zone = zone
	return mission

func _generate_quick_mission() -> Mission:
	"""Generate a quick mission (15-45 seconds)"""
	if not game_manager:
		return null
	
	missions_generated += 1
	
	var templates = MissionData.get_mission_templates()
	var template = templates[randi() % templates.size()]
	
	# Weight by current chaos levels
	var zone = _pick_weighted_zone()
	var difficulty = _pick_difficulty_by_urgency()
	
	var mission = Mission.new(
		"rapid_mission_" + str(missions_generated),
		template.name,
		template.emoji,
		template.description,
		difficulty
	)
	
	mission.zone = zone
	
	# Quick missions!
	match difficulty:
		Mission.Difficulty.EASY:
			mission.base_duration = randf_range(15.0, 25.0)
			mission.money_reward = randi_range(30, 60)
			mission.fame_reward = randi_range(3, 6)
		Mission.Difficulty.MEDIUM:
			mission.base_duration = randf_range(20.0, 35.0)
			mission.money_reward = randi_range(50, 100)
			mission.fame_reward = randi_range(5, 12)
		Mission.Difficulty.HARD:
			mission.base_duration = randf_range(30.0, 45.0)
			mission.money_reward = randi_range(80, 150)
			mission.fame_reward = randi_range(10, 20)
		Mission.Difficulty.EXTREME:
			mission.base_duration = randf_range(40.0, 60.0)
			mission.money_reward = randi_range(120, 250)
			mission.fame_reward = randi_range(18, 35)
	
	# Streak bonuses
	if current_streak >= STREAK_BONUS_THRESHOLD:
		var multiplier = 1.0 + (current_streak / 10.0)
		mission.money_reward = int(mission.money_reward * multiplier)
		mission.fame_reward = int(mission.fame_reward * multiplier)
	
	mission.min_heroes = 1
	mission.max_heroes = 1  # One hero per mission for simplicity
	
	# Set specialties
	var specs_array: Array[Hero.Specialty] = []
	for spec in template.specialties:
		specs_array.append(spec)
	mission.preferred_specialties = specs_array
	
	# Apply chaos effects
	if game_manager.chaos_system:
		game_manager.chaos_system.apply_chaos_to_mission(mission)
	
	return mission

func _pick_weighted_zone() -> String:
	"""Pick zone weighted by chaos level (higher chaos = more missions)"""
	var zones = ["downtown", "industrial", "residential", "park", "waterfront"]
	
	if not game_manager or not game_manager.chaos_system:
		return zones[randi() % zones.size()]
	
	var weights = []
	var total_weight = 0.0
	
	for zone in zones:
		var chaos = game_manager.chaos_system.get_chaos_level(zone)
		var weight = 1.0 + (chaos / 50.0)  # Higher chaos = more weight
		weights.append(weight)
		total_weight += weight
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for i in range(zones.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return zones[i]
	
	return zones[0]

func _pick_difficulty_by_urgency() -> Mission.Difficulty:
	"""Pick difficulty based on average chaos"""
	if not game_manager or not game_manager.chaos_system:
		return Mission.Difficulty.EASY
	
	var avg_chaos = 0.0
	var zones = ["downtown", "industrial", "residential", "park", "waterfront"]
	for zone in zones:
		avg_chaos += game_manager.chaos_system.get_chaos_level(zone)
	avg_chaos /= zones.size()
	
	var roll = randf() * 100.0
	
	if avg_chaos < 25.0:
		# Low urgency
		if roll < 60.0:
			return Mission.Difficulty.EASY
		elif roll < 85.0:
			return Mission.Difficulty.MEDIUM
		elif roll < 95.0:
			return Mission.Difficulty.HARD
		else:
			return Mission.Difficulty.EXTREME
	elif avg_chaos < 50.0:
		# Medium urgency
		if roll < 40.0:
			return Mission.Difficulty.EASY
		elif roll < 70.0:
			return Mission.Difficulty.MEDIUM
		elif roll < 90.0:
			return Mission.Difficulty.HARD
		else:
			return Mission.Difficulty.EXTREME
	else:
		# High urgency
		if roll < 20.0:
			return Mission.Difficulty.EASY
		elif roll < 45.0:
			return Mission.Difficulty.MEDIUM
		elif roll < 75.0:
			return Mission.Difficulty.HARD
		else:
			return Mission.Difficulty.EXTREME

func get_current_mission() -> Mission:
	"""Get the mission at the front of the queue (respecting zone filter)"""
	if mission_queue.is_empty():
		_fill_mission_queue()
	
	if mission_queue.is_empty():
		return null
	
	# If filtering by zone, find first mission in that zone
	if current_zone_filter != "all":
		for mission in mission_queue:
			if mission.zone == current_zone_filter:
				return mission
		# No missions in filtered zone, return first mission anyway
		# (or could return null to show "no missions in this zone")
	
	return mission_queue[0]

func set_zone_filter(zone_id: String) -> void:
	"""Set zone filter - 'all' or specific zone name"""
	print("🗺️ Zone filter set to: %s" % zone_id)
	current_zone_filter = zone_id
	
	# If switching to specific zone, try to fill queue with missions from that zone
	if zone_id != "all":
		_ensure_zone_missions(zone_id)

func accept_mission() -> bool:
	"""Accept the current mission and auto-assign best available hero"""
	var mission = get_current_mission()
	if not mission:
		return false
	
	# Find best available hero
	var best_hero = _find_best_hero_for_mission(mission)
	
	if not best_hero:
		print("❌ No heroes available!")
		return false
	
	# Check if we have an available slot
	if active_slots.size() >= MAX_ACTIVE_SLOTS:
		print("❌ All mission slots full!")
		return false
	
	# Remove from queue (remove the actual mission object)
	mission_queue.erase(mission)
	_fill_mission_queue()
	
	# Drain hero energy
	hero_energy[best_hero.hero_id] -= ENERGY_DRAIN_PER_MISSION
	if hero_energy[best_hero.hero_id] <= 0:
		hero_energy[best_hero.hero_id] = 0
		hero_energy_depleted.emit(best_hero)
	
	# Start mission
	mission.assigned_hero_ids.append(best_hero.hero_id)
	mission.start_mission([best_hero])
	
	# Add to active slots
	active_slots.append({
		"mission": mission,
		"hero": best_hero,
		"time_remaining": mission.base_duration
	})
	
	# Update streak
	current_streak += 1
	if current_streak > best_streak:
		best_streak = current_streak
	streak_increased.emit(current_streak)
	
	print("✅ MISSION ACCEPTED: %s by %s (Streak: %d)" % [mission.mission_name, best_hero.hero_name, current_streak])
	
	mission_accepted.emit(mission)
	return true

func decline_mission() -> void:
	"""Decline the current mission (increases chaos, breaks streak)"""
	var mission = get_current_mission()
	if not mission:
		return
	
	mission_queue.erase(mission)
	_fill_mission_queue()
	
	# Increase chaos in that zone
	if game_manager and game_manager.chaos_system:
		var chaos_increase = 3.0 + (mission.difficulty * 2.0)
		var zone = mission.zone
		var old_chaos = game_manager.chaos_system.get_chaos_level(zone)
		game_manager.chaos_system.zone_chaos[zone] = min(100.0, old_chaos + chaos_increase)
		print("⚠️ MISSION DECLINED: %s - %s chaos +%.1f (%.0f%% -> %.0f%%)" % [
			mission.mission_name, 
			zone, 
			chaos_increase,
			old_chaos,
			game_manager.chaos_system.zone_chaos[zone]
		])
	
	# Break streak
	if current_streak > 0:
		current_streak = 0
		streak_broken.emit()
	
	missions_declined_total += 1
	mission_declined.emit(mission)

func _find_best_hero_for_mission(mission: Mission) -> Hero:
	"""Find the best available hero for a mission"""
	var available_heroes = []
	
	for hero in game_manager.heroes:
		if hero.is_available() and hero_energy.get(hero.hero_id, 0) >= ENERGY_DRAIN_PER_MISSION:
			available_heroes.append(hero)
	
	if available_heroes.is_empty():
		return null
	
	# Score heroes
	var best_hero = null
	var best_score = -999
	
	for hero in available_heroes:
		var score = hero.get_power_rating()
		
		# Bonus for matching specialties
		for spec in mission.preferred_specialties:
			if spec in hero.specialties:
				score += 15
		
		# Bonus for higher energy
		var energy_percent = hero_energy.get(hero.hero_id, 100.0)
		score += energy_percent * 0.1
		
		if score > best_score:
			best_score = score
			best_hero = hero
	
	return best_hero

func _update_active_missions(delta: float) -> void:
	"""Update all active mission timers"""
	var completed = []
	
	for slot in active_slots:
		slot.time_remaining -= delta
		
		if slot.time_remaining <= 0:
			completed.append(slot)
	
	for slot in completed:
		_complete_mission_slot(slot)

func _complete_mission_slot(slot: Dictionary) -> void:
	"""Complete a mission and give rewards"""
	var mission: Mission = slot.mission
	var hero: Hero = slot.hero
	
	var result = mission.complete_mission()
	
	# Update chaos
	if game_manager.chaos_system:
		if result.success:
			game_manager.chaos_system.on_mission_success(mission)
			var prevented = 8.0 + (mission.difficulty * 2.0)
			total_chaos_prevented += prevented
		else:
			game_manager.chaos_system.on_mission_failed(mission)
	
	# Give rewards
	game_manager.add_money(result.money)
	game_manager.add_fame(result.fame)
	hero.add_experience(result.exp)
	
	# Damage risk
	if not result.success or randf() < mission.damage_risk:
		var damage = randf_range(10, 20)
		hero.take_damage(damage)
	
	# Update stats
	missions_completed_total += 1
	
	# Return hero
	hero.is_on_mission = false
	hero.current_mission_id = ""
	
	# Remove from active slots
	active_slots.erase(slot)
	
	print("✅ Mission completed: %s by %s" % [mission.mission_name, hero.hero_name])

func _regenerate_hero_energy(delta: float) -> void:
	"""Regenerate energy for all heroes"""
	for hero_id in hero_energy.keys():
		if hero_energy[hero_id] < 100.0:
			hero_energy[hero_id] = min(100.0, hero_energy[hero_id] + ENERGY_REGEN_PER_SECOND * delta)

func get_hero_energy(hero_id: String) -> float:
	return hero_energy.get(hero_id, 100.0)

func get_available_heroes_count() -> int:
	var count = 0
	for hero in game_manager.heroes:
		if hero.is_available() and hero_energy.get(hero.hero_id, 0) >= ENERGY_DRAIN_PER_MISSION:
			count += 1
	return count

func get_stats() -> Dictionary:
	return {
		"completed": missions_completed_total,
		"declined": missions_declined_total,
		"streak": current_streak,
		"best_streak": best_streak,
		"chaos_prevented": total_chaos_prevented,
		"active_missions": active_slots.size()
	}

func serialize() -> Dictionary:
	return {
		"missions_generated": missions_generated,
		"current_streak": current_streak,
		"best_streak": best_streak,
		"missions_completed": missions_completed_total,
		"missions_declined": missions_declined_total,
		"total_chaos_prevented": total_chaos_prevented,
		"hero_energy": hero_energy.duplicate(),
		"current_zone_filter": current_zone_filter
	}

func deserialize(data: Dictionary) -> void:
	missions_generated = data.get("missions_generated", 0)
	current_streak = data.get("current_streak", 0)
	best_streak = data.get("best_streak", 0)
	missions_completed_total = data.get("missions_completed", 0)
	missions_declined_total = data.get("missions_declined", 0)
	total_chaos_prevented = data.get("total_chaos_prevented", 0.0)
	hero_energy = data.get("hero_energy", {}).duplicate()
	current_zone_filter = data.get("current_zone_filter", "all")
