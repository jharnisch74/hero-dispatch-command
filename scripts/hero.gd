# res://scripts/hero.gd
extends RefCounted
class_name Hero

# Hero identification
var hero_id: String
var hero_name: String
var hero_emoji: String

# Core stats
var level: int = 1
var experience: int = 0
var exp_to_next_level: int = 100

# Combat stats
var base_strength: int = 5
var base_speed: int = 5
var base_intelligence: int = 5

# Modifiers from upgrades
var strength_modifier: int = 0
var speed_modifier: int = 0
var intelligence_modifier: int = 0

# Status
var current_health: float = 100.0
var max_health: float = 100.0
var current_stamina: float = 100.0
var max_stamina: float = 100.0

# State tracking
var is_on_mission: bool = false
var is_recovering: bool = false
var recovery_time_remaining: float = 0.0
var current_mission_id: String = ""

# Specializations (affects mission success)
enum Specialty {COMBAT, SPEED, TECH, RESCUE, INVESTIGATION}
var specialties: Array[Specialty] = []

# Economy
var upgrade_cost_multiplier: float = 1.0

func _init(id: String, name: String, emoji: String, spec: Array[Specialty]):
	hero_id = id
	hero_name = name
	hero_emoji = emoji
	specialties = spec
	_randomize_base_stats()

func _randomize_base_stats() -> void:
	base_strength = randi_range(3, 8)
	base_speed = randi_range(3, 8)
	base_intelligence = randi_range(3, 8)

func get_total_strength() -> int:
	return base_strength + strength_modifier + (level - 1)

func get_total_speed() -> int:
	return base_speed + speed_modifier + (level - 1)

func get_total_intelligence() -> int:
	return base_intelligence + intelligence_modifier + (level - 1)

func get_power_rating() -> int:
	return get_total_strength() + get_total_speed() + get_total_intelligence()

func get_specialties() -> Array:
	return specialties

func is_available() -> bool:
	return not is_on_mission and not is_recovering and current_health > 0 and current_stamina >= 20

func take_damage(amount: float) -> void:
	current_health = max(0, current_health - amount)
	if current_health == 0:
		start_recovery(30.0)

func use_stamina(amount: float) -> void:
	current_stamina = max(0, current_stamina - amount)

func start_recovery(duration: float) -> void:
	is_recovering = true
	recovery_time_remaining = duration

func update_recovery(delta: float) -> void:
	if is_recovering:
		recovery_time_remaining -= delta
		if recovery_time_remaining <= 0:
			recovery_time_remaining = 0
			is_recovering = false
			current_health = max_health
			current_stamina = max_stamina

func regen_stamina(delta: float) -> void:
	if not is_on_mission and not is_recovering:
		current_stamina = min(max_stamina, current_stamina + delta * 5.0)

func add_experience(amount: int) -> void:
	experience += amount
	while experience >= exp_to_next_level:
		level_up()

func level_up() -> void:
	experience -= exp_to_next_level
	level += 1
	exp_to_next_level = int(exp_to_next_level * 1.5)
	max_health += 10
	max_stamina += 10
	current_health = max_health
	current_stamina = max_stamina

func get_upgrade_cost(stat_type: String) -> int:
	var base_cost = 100
	match stat_type:
		"strength":
			return int(base_cost * (1 + strength_modifier * 0.5) * upgrade_cost_multiplier)
		"speed":
			return int(base_cost * (1 + speed_modifier * 0.5) * upgrade_cost_multiplier)
		"intelligence":
			return int(base_cost * (1 + intelligence_modifier * 0.5) * upgrade_cost_multiplier)
		"max_health":
			return int(base_cost * 2 * (1 + (max_health - 100) / 50) * upgrade_cost_multiplier)
		"max_stamina":
			return int(base_cost * 2 * (1 + (max_stamina - 100) / 50) * upgrade_cost_multiplier)
	return 999999

func upgrade_stat(stat_type: String) -> bool:
	match stat_type:
		"strength":
			strength_modifier += 1
			return true
		"speed":
			speed_modifier += 1
			return true
		"intelligence":
			intelligence_modifier += 1
			return true
		"max_health":
			max_health += 20
			current_health = max_health
			return true
		"max_stamina":
			max_stamina += 20
			current_stamina = max_stamina
			return true
	return false

func get_status_text() -> String:
	if is_on_mission:
		return "🚀 On Mission"
	elif is_recovering:
		return "💤 Recovering (%ds)" % int(recovery_time_remaining)
	elif current_health < max_health * 0.3:
		return "🩹 Injured"
	elif current_stamina < 20:
		return "😓 Exhausted"
	return "✅ Ready"

func get_health_percent() -> float:
	return (current_health / max_health) * 100.0

func get_stamina_percent() -> float:
	return (current_stamina / max_stamina) * 100.0
