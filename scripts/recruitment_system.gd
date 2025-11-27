# res://scripts/recruitment_system.gd
extends Node
class_name RecruitmentSystem

# Hero Rarities
enum Rarity {COMMON, RARE, EPIC, LEGENDARY}

# Recruitment costs
const STANDARD_RECRUIT_COST = 500
const PREMIUM_RECRUIT_COST = 2000

# Pity system
var standard_pity_counter: int = 0
var premium_pity_counter: int = 0
const PREMIUM_PITY_THRESHOLD = 10  # Guaranteed epic every 10 pulls

# Game manager reference
var game_manager: Node

signal hero_recruited(hero: Hero, rarity: Rarity)
signal recruitment_failed(reason: String)

func _init(gm: Node = null):
	game_manager = gm

# Get all possible recruitable heroes
func get_hero_pool() -> Array:
	return [
		# COMMON HEROES (60% chance)
		{
			"name": "Street Guardian",
			"emoji": "🥊",
			"specialties": [Hero.Specialty.COMBAT],
			"rarity": Rarity.COMMON
		},
		{
			"name": "Fast Response",
			"emoji": "💨",
			"specialties": [Hero.Specialty.SPEED],
			"rarity": Rarity.COMMON
		},
		{
			"name": "Tech Support",
			"emoji": "🔧",
			"specialties": [Hero.Specialty.TECH],
			"rarity": Rarity.COMMON
		},
		{
			"name": "First Responder",
			"emoji": "🚑",
			"specialties": [Hero.Specialty.RESCUE],
			"rarity": Rarity.COMMON
		},
		{
			"name": "Beat Cop",
			"emoji": "👮",
			"specialties": [Hero.Specialty.INVESTIGATION],
			"rarity": Rarity.COMMON
		},
		{
			"name": "Rookie Hero",
			"emoji": "🦸",
			"specialties": [Hero.Specialty.COMBAT],
			"rarity": Rarity.COMMON
		},
		
		# RARE HEROES (30% chance)
		{
			"name": "Shadow Strike",
			"emoji": "🥷",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED],
			"rarity": Rarity.RARE
		},
		{
			"name": "Cyber Sentinel",
			"emoji": "🤖",
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.INVESTIGATION],
			"rarity": Rarity.RARE
		},
		{
			"name": "Blaze Runner",
			"emoji": "🔥",
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.SPEED],
			"rarity": Rarity.RARE
		},
		{
			"name": "Iron Fist",
			"emoji": "🦾",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.TECH],
			"rarity": Rarity.RARE
		},
		{
			"name": "Mind Reader",
			"emoji": "🧠",
			"specialties": [Hero.Specialty.INVESTIGATION, Hero.Specialty.RESCUE],
			"rarity": Rarity.RARE
		},
		
		# EPIC HEROES (9% chance)
		{
			"name": "Thunder Strike",
			"emoji": "⚡",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED, Hero.Specialty.TECH],
			"rarity": Rarity.EPIC
		},
		{
			"name": "Phoenix",
			"emoji": "🔥",
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.COMBAT, Hero.Specialty.SPEED],
			"rarity": Rarity.EPIC
		},
		{
			"name": "Detective Noir",
			"emoji": "🕵️",
			"specialties": [Hero.Specialty.INVESTIGATION, Hero.Specialty.TECH, Hero.Specialty.COMBAT],
			"rarity": Rarity.EPIC
		},
		{
			"name": "Titanium",
			"emoji": "🛡️",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.RESCUE, Hero.Specialty.TECH],
			"rarity": Rarity.EPIC
		},
		
		# LEGENDARY HEROES (1% chance)
		{
			"name": "Omega Prime",
			"emoji": "👑",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED, Hero.Specialty.TECH, Hero.Specialty.INVESTIGATION],
			"rarity": Rarity.LEGENDARY
		},
		{
			"name": "Celestial",
			"emoji": "✨",
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.COMBAT, Hero.Specialty.SPEED, Hero.Specialty.TECH],
			"rarity": Rarity.LEGENDARY
		},
		{
			"name": "Apex",
			"emoji": "💎",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.INVESTIGATION, Hero.Specialty.TECH, Hero.Specialty.RESCUE],
			"rarity": Rarity.LEGENDARY
		}
	]

func get_starting_heroes() -> Array:
	"""Returns 3 balanced starter heroes"""
	return [
		{
			"name": "Captain Justice",
			"emoji": "🦸‍♂️",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.RESCUE],
			"rarity": Rarity.RARE
		},
		{
			"name": "Tech Wizard",
			"emoji": "🧙‍♂️",
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.INVESTIGATION],
			"rarity": Rarity.RARE
		},
		{
			"name": "Swift Shadow",
			"emoji": "🦇",
			"specialties": [Hero.Specialty.SPEED, Hero.Specialty.INVESTIGATION],
			"rarity": Rarity.RARE
		}
	]

func can_afford_recruit(is_premium: bool) -> bool:
	if not game_manager:
		return false
	
	var cost = PREMIUM_RECRUIT_COST if is_premium else STANDARD_RECRUIT_COST
	return game_manager.money >= cost

func standard_recruit() -> Hero:
	"""Standard recruitment - Common/Rare heroes"""
	if not game_manager:
		recruitment_failed.emit("No game manager reference")
		return null
	
	if not can_afford_recruit(false):
		recruitment_failed.emit("Not enough money! Need $%d" % STANDARD_RECRUIT_COST)
		return null
	
	# Deduct cost
	game_manager.spend_money(STANDARD_RECRUIT_COST)
	
	# Roll for hero
	var hero_data = _roll_hero(false)
	var hero = _create_hero_from_data(hero_data)
	
	# Add to game
	game_manager.heroes.append(hero)
	
	# Increment pity counter
	standard_pity_counter += 1
	
	# Emit signal
	hero_recruited.emit(hero, hero_data.rarity)
	
	print("✨ RECRUITED: %s (%s)" % [hero.hero_name, _get_rarity_name(hero_data.rarity)])
	
	return hero

func premium_recruit() -> Hero:
	"""Premium recruitment - Rare/Epic/Legendary heroes"""
	if not game_manager:
		recruitment_failed.emit("No game manager reference")
		return null
	
	if not can_afford_recruit(true):
		recruitment_failed.emit("Not enough money! Need $%d" % PREMIUM_RECRUIT_COST)
		return null
	
	# Deduct cost
	game_manager.spend_money(PREMIUM_RECRUIT_COST)
	
	# Check pity system
	premium_pity_counter += 1
	var guaranteed_epic = premium_pity_counter >= PREMIUM_PITY_THRESHOLD
	
	# Roll for hero
	var hero_data = _roll_hero(true, guaranteed_epic)
	var hero = _create_hero_from_data(hero_data)
	
	# Add to game
	game_manager.heroes.append(hero)
	
	# Reset pity if epic or legendary
	if hero_data.rarity >= Rarity.EPIC:
		premium_pity_counter = 0
	
	# Emit signal
	hero_recruited.emit(hero, hero_data.rarity)
	
	print("✨ PREMIUM RECRUITED: %s (%s)" % [hero.hero_name, _get_rarity_name(hero_data.rarity)])
	
	return hero

func _roll_hero(is_premium: bool, guaranteed_epic: bool = false) -> Dictionary:
	"""Roll for a random hero based on rarity chances"""
	var pool = get_hero_pool()
	
	# Determine rarity first
	var rarity: Rarity
	
	if guaranteed_epic:
		# Pity system: guaranteed epic or legendary
		var epic_or_legendary = pool.filter(func(h): return h.rarity >= Rarity.EPIC)
		return epic_or_legendary[randi() % epic_or_legendary.size()]
	
	var roll = randf() * 100.0
	
	if is_premium:
		# Premium rates: 0% common, 40% rare, 50% epic, 10% legendary
		if roll < 10.0:
			rarity = Rarity.LEGENDARY
		elif roll < 60.0:
			rarity = Rarity.EPIC
		else:
			rarity = Rarity.RARE
	else:
		# Standard rates: 60% common, 30% rare, 9% epic, 1% legendary
		if roll < 1.0:
			rarity = Rarity.LEGENDARY
		elif roll < 10.0:
			rarity = Rarity.EPIC
		elif roll < 40.0:
			rarity = Rarity.RARE
		else:
			rarity = Rarity.COMMON
	
	# Get all heroes of that rarity
	var candidates = pool.filter(func(h): return h.rarity == rarity)
	
	# Filter out already owned heroes (optional - can allow duplicates)
	var unowned = candidates.filter(func(h): 
		return not _is_hero_owned(h.name)
	)
	
	# If all owned, allow duplicates
	if unowned.size() == 0:
		unowned = candidates
	
	# Return random hero from candidates
	return unowned[randi() % unowned.size()]

func _is_hero_owned(hero_name: String) -> bool:
	"""Check if player already owns this hero"""
	if not game_manager:
		return false
	
	for hero in game_manager.heroes:
		if hero.hero_name == hero_name:
			return true
	return false

func _create_hero_from_data(data: Dictionary) -> Hero:
	"""Create a Hero instance from recruitment data"""
	var specs_array: Array[Hero.Specialty] = []
	for spec in data.specialties:
		specs_array.append(spec)
	
	var hero_id = "hero_" + str(Time.get_ticks_msec())
	var hero = Hero.new(hero_id, data.name, data.emoji, specs_array)
	
	# Boost stats based on rarity
	match data.rarity:
		Rarity.COMMON:
			# Base stats (3-8)
			pass
		Rarity.RARE:
			# +2 to all stats
			hero.base_strength += 2
			hero.base_speed += 2
			hero.base_intelligence += 2
		Rarity.EPIC:
			# +4 to all stats
			hero.base_strength += 4
			hero.base_speed += 4
			hero.base_intelligence += 4
			hero.max_health += 20
			hero.current_health = hero.max_health
		Rarity.LEGENDARY:
			# +6 to all stats
			hero.base_strength += 6
			hero.base_speed += 6
			hero.base_intelligence += 6
			hero.max_health += 40
			hero.max_stamina += 20
			hero.current_health = hero.max_health
			hero.current_stamina = hero.max_stamina
	
	return hero

func _get_rarity_name(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "COMMON"
		Rarity.RARE:
			return "RARE"
		Rarity.EPIC:
			return "EPIC"
		Rarity.LEGENDARY:
			return "LEGENDARY"
	return "UNKNOWN"

func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:
			return Color("#9e9e9e")  # Gray
		Rarity.RARE:
			return Color("#4caf50")  # Green
		Rarity.EPIC:
			return Color("#9c27b0")  # Purple
		Rarity.LEGENDARY:
			return Color("#ff9800")  # Orange
	return Color.WHITE

func serialize() -> Dictionary:
	return {
		"standard_pity": standard_pity_counter,
		"premium_pity": premium_pity_counter
	}

func deserialize(data: Dictionary) -> void:
	standard_pity_counter = data.get("standard_pity", 0)
	premium_pity_counter = data.get("premium_pity", 0)

func reset() -> void:
	"""Reset pity counters"""
	standard_pity_counter = 0
	premium_pity_counter = 0
	print("RecruitmentSystem: Pity counters reset")
