# res://scripts/mission.gd
extends RefCounted
class_name Mission

# Mission identification
var mission_id: String
var mission_name: String
var mission_emoji: String
var description: String
var zone: String = "downtown"

# Difficulty
enum Difficulty {EASY, MEDIUM, HARD, EXTREME}
var difficulty: Difficulty

# Requirements
var required_power: int
var preferred_specialties: Array[Hero.Specialty] = []
var min_heroes: int = 1
var max_heroes: int = 3

# Rewards
var money_reward: int
var fame_reward: int
var exp_reward: int

# Timing
var base_duration: float
var time_remaining: float = 0.0
var is_active: bool = false
var is_completed: bool = false

# NEW: Mission availability timeout
var availability_timeout: float = 60.0  # Missions expire after 60 seconds if not started
var availability_timer: float = 0.0
var is_expired: bool = false

# Assigned heroes
var assigned_hero_ids: Array[String] = []

# Success calculation
var success_chance: float = 0.0
var damage_risk: float = 0.0

func _init(id: String, name: String, emoji: String, desc: String, diff: Difficulty):
	mission_id = id
	mission_name = name
	mission_emoji = emoji
	description = desc
	difficulty = diff
	_set_difficulty_params()

func _set_difficulty_params() -> void:
	match difficulty:
		Difficulty.EASY:
			required_power = 15
			money_reward = randi_range(50, 100)
			fame_reward = randi_range(5, 10)
			exp_reward = 20
			base_duration = 10.0
			damage_risk = 0.1
			availability_timeout = 90.0  # Easy missions last longer
		Difficulty.MEDIUM:
			required_power = 30
			money_reward = randi_range(150, 250)
			fame_reward = randi_range(15, 25)
			exp_reward = 50
			base_duration = 20.0
			damage_risk = 0.25
			availability_timeout = 75.0
		Difficulty.HARD:
			required_power = 50
			money_reward = randi_range(300, 500)
			fame_reward = randi_range(30, 50)
			exp_reward = 100
			base_duration = 35.0
			damage_risk = 0.4
			availability_timeout = 60.0
		Difficulty.EXTREME:
			required_power = 80
			money_reward = randi_range(600, 1000)
			fame_reward = randi_range(60, 100)
			exp_reward = 200
			base_duration = 50.0
			damage_risk = 0.6
			availability_timeout = 45.0  # EXTREME missions expire quickly!

func update_availability_timer(delta: float) -> bool:
	"""Update the availability timer. Returns true if mission expired."""
	if is_active or is_completed or is_expired:
		return false
	
	availability_timer += delta
	
	if availability_timer >= availability_timeout:
		is_expired = true
		return true
	
	return false

func get_time_until_expiry() -> float:
	"""Returns seconds remaining before mission expires"""
	return max(0.0, availability_timeout - availability_timer)

func get_expiry_percent() -> float:
	"""Returns percentage of time remaining (100% = just spawned, 0% = expired)"""
	return (1.0 - (availability_timer / availability_timeout)) * 100.0

func can_start() -> bool:
	return assigned_hero_ids.size() >= min_heroes and not is_active and not is_completed and not is_expired

func start_mission(heroes: Array[Hero]) -> void:
	if not can_start():
		return
	
	is_active = true
	time_remaining = base_duration
	
	# Calculate success chance
	var total_power = 0
	var specialty_bonus = 0.0
	
	for hero in heroes:
		if hero.hero_id in assigned_hero_ids:
			total_power += hero.get_power_rating()
			hero.is_on_mission = true
			hero.current_mission_id = mission_id
			
			# Check specialty match
			for spec in preferred_specialties:
				if spec in hero.specialties:
					specialty_bonus += 0.15
	
	# Calculate success chance (0.0 to 1.0)
	var power_ratio = float(total_power) / float(required_power)
	success_chance = clamp(power_ratio * 0.7 + specialty_bonus, 0.1, 0.95)
	
	# Adjust duration based on team speed
	var avg_speed = 0
	for hero in heroes:
		if hero.hero_id in assigned_hero_ids:
			avg_speed += hero.get_total_speed()
	avg_speed /= assigned_hero_ids.size()
	
	var speed_multiplier = 1.0 - (avg_speed / 100.0)
	time_remaining *= clamp(speed_multiplier, 0.5, 1.0)

func update_mission(delta: float) -> bool:
	if not is_active:
		return false
	
	time_remaining -= delta
	
	if time_remaining <= 0:
		complete_mission()
		return true
	
	return false

func complete_mission() -> Dictionary:
	is_active = false
	is_completed = true
	time_remaining = 0.0
	
	# Determine success
	var roll = randf()
	var success = roll < success_chance
	
	var result = {
		"success": success,
		"money": 0,
		"fame": 0,
		"exp": 0,
		"hero_ids": assigned_hero_ids.duplicate()
	}
	
	if success:
		result.money = money_reward
		result.fame = fame_reward
		result.exp = exp_reward
	else:
		# Partial rewards on failure
		result.money = int(money_reward * 0.3)
		result.fame = int(fame_reward * 0.2)
		result.exp = int(exp_reward * 0.5)
	
	return result

func assign_hero(hero_id: String) -> bool:
	if assigned_hero_ids.size() >= max_heroes:
		return false
	if hero_id in assigned_hero_ids:
		return false
	assigned_hero_ids.append(hero_id)
	return true

func unassign_hero(hero_id: String) -> bool:
	if hero_id in assigned_hero_ids:
		assigned_hero_ids.erase(hero_id)
		return true
	return false

func get_difficulty_string() -> String:
	match difficulty:
		Difficulty.EASY:
			return "⭐ Easy"
		Difficulty.MEDIUM:
			return "⭐⭐ Medium"
		Difficulty.HARD:
			return "⭐⭐⭐ Hard"
		Difficulty.EXTREME:
			return "⭐⭐⭐⭐ EXTREME"
	return "Unknown"

func get_difficulty_color() -> Color:
	match difficulty:
		Difficulty.EASY:
			return Color("#4ecca3")
		Difficulty.MEDIUM:
			return Color("#ffd700")
		Difficulty.HARD:
			return Color("#ff8c42")
		Difficulty.EXTREME:
			return Color("#ff3838")
	return Color.WHITE

func get_requirements_text() -> String:
	var text = "Power Needed: %d" % required_power
	if preferred_specialties.size() > 0:
		text += " | Prefers: "
		var spec_names = []
		for spec in preferred_specialties:
			match spec:
				Hero.Specialty.COMBAT:
					spec_names.append("Combat")
				Hero.Specialty.SPEED:
					spec_names.append("Speed")
				Hero.Specialty.TECH:
					spec_names.append("Tech")
				Hero.Specialty.RESCUE:
					spec_names.append("Rescue")
				Hero.Specialty.INVESTIGATION:
					spec_names.append("Investigation")
		text += ", ".join(spec_names)
	return text

func get_progress_percent() -> float:
	if base_duration == 0:
		return 0.0
	return ((base_duration - time_remaining) / base_duration) * 100.0
