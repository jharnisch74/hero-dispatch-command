# res://scripts/game_manager.gd
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

# UI References (set by Main scene)
var hero_list_container: VBoxContainer
var mission_list_container: VBoxContainer
var money_label: Label
var fame_label: Label
var status_label: Label

# Card scenes (preload)
var hero_card_scene = preload("res://scenes/ui/hero_card.tscn")
var mission_card_scene = preload("res://scenes/ui/mission_card.tscn")

# Signals
signal money_changed(new_amount: int)
signal fame_changed(new_amount: int)
signal hero_updated(hero: Hero)
signal mission_completed(mission: Mission, result: Dictionary)

func _ready() -> void:
	_initialize_starting_heroes()
	_spawn_initial_missions()

func _process(delta: float) -> void:
	_update_heroes(delta)
	_update_active_missions(delta)
	_update_mission_spawning(delta)

func _initialize_starting_heroes() -> void:
	# Create starting roster
	var starting_heroes = [
		{
			"name": "Captain Thunder",
			"emoji": "⚡",
			"specs": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED]
		},
		{
			"name": "Shadow Strike",
			"emoji": "🥷",
			"specs": [Hero.Specialty.SPEED, Hero.Specialty.INVESTIGATION]
		},
		{
			"name": "Tech Wizard",
			"emoji": "🧙",
			"specs": [Hero.Specialty.TECH, Hero.Specialty.INVESTIGATION]
		},
		{
			"name": "Guardian",
			"emoji": "🛡️",
			"specs": [Hero.Specialty.RESCUE, Hero.Specialty.COMBAT]
		}
	]
	
	for hero_data in starting_heroes:
		var hero = Hero.new(
			"hero_" + str(heroes.size()),
			hero_data.name,
			hero_data.emoji,
			hero_data.specs
		)
		heroes.append(hero)

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
	
	# Process completed missions
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
	
	# Mission templates
	var mission_templates = [
		{"name": "Cat Rescue", "emoji": "🐱", "desc": "Save a cat stuck in a tree", "diff": Mission.Difficulty.EASY, "specs": [Hero.Specialty.RESCUE]},
		{"name": "Bank Robbery", "emoji": "🏦", "desc": "Stop criminals robbing the city bank", "diff": Mission.Difficulty.MEDIUM, "specs": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED]},
		{"name": "Hostage Crisis", "emoji": "🏢", "desc": "Rescue hostages from a building", "diff": Mission.Difficulty.HARD, "specs": [Hero.Specialty.RESCUE, Hero.Specialty.INVESTIGATION]},
		{"name": "Cyber Attack", "emoji": "💻", "desc": "Stop hackers from stealing city data", "diff": Mission.Difficulty.MEDIUM, "specs": [Hero.Specialty.TECH]},
		{"name": "Super Villain", "emoji": "🦹", "desc": "Defeat the infamous Dr. Chaos", "diff": Mission.Difficulty.EXTREME, "specs": [Hero.Specialty.COMBAT]},
		{"name": "Bomb Threat", "emoji": "💣", "desc": "Defuse bombs across the city", "diff": Mission.Difficulty.HARD, "specs": [Hero.Specialty.TECH, Hero.Specialty.SPEED]},
		{"name": "Investigation", "emoji": "🔍", "desc": "Solve a mysterious disappearance", "diff": Mission.Difficulty.MEDIUM, "specs": [Hero.Specialty.INVESTIGATION]},
		{"name": "Fire Rescue", "emoji": "🔥", "desc": "Save people from a burning building", "diff": Mission.Difficulty.MEDIUM, "specs": [Hero.Specialty.RESCUE, Hero.Specialty.SPEED]},
		{"name": "Gang War", "emoji": "⚔️", "desc": "Stop warring criminal factions", "diff": Mission.Difficulty.HARD, "specs": [Hero.Specialty.COMBAT]},
		{"name": "Lost Pet", "emoji": "🐕", "desc": "Find a lost puppy in the park", "diff": Mission.Difficulty.EASY, "specs": [Hero.Specialty.INVESTIGATION]},
		{"name": "Alien Invasion", "emoji": "👽", "desc": "Repel extraterrestrial attackers", "diff": Mission.Difficulty.EXTREME, "specs": [Hero.Specialty.COMBAT, Hero.Specialty.TECH]},
		{"name": "Bridge Collapse", "emoji": "🌉", "desc": "Save civilians from a collapsing bridge", "diff": Mission.Difficulty.HARD, "specs": [Hero.Specialty.RESCUE]},
	]
	
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
	
	# Pick a random template and adjust difficulty
	var template = mission_templates[randi() % mission_templates.size()]
	var difficulty = _pick_weighted_difficulty(difficulty_weights)
	
	var mission = Mission.new(
		"mission_" + str(mission_counter),
		template.name,
		template.emoji,
		template.desc,
		difficulty
	)
	
	mission.preferred_specialties = template.specs
	mission.max_heroes = 1 if difficulty == Mission.Difficulty.EASY else (3 if difficulty == Mission.Difficulty.EXTREME else 2)
	
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
		update_status("❌ Hero is not available!")
		return false
	
	if mission.is_active or mission.is_completed:
		update_status("❌ Mission already started or completed!")
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
	
	# Get assigned heroes
	var assigned_heroes: Array[Hero] = []
	for hero in heroes:
		if hero.hero_id in mission.assigned_hero_ids:
			assigned_heroes.append(hero)
	
	# Use stamina
	for hero in assigned_heroes:
		hero.use_stamina(30.0)
	
	mission.start_mission(assigned_heroes)
	available_missions.erase(mission)
	active_missions.append(mission)
	
	update_status("🚀 Mission started: %s" % mission.mission_name)
	return true

func _complete_mission(mission: Mission) -> void:
	var result = mission.complete_mission()
	
	# Award resources
	add_money(result.money)
	add_fame(result.fame)
	
	# Update heroes
	var hero_names = []
	for hero_id in result.hero_ids:
		var hero = get_hero_by_id(hero_id)
		if hero:
			hero_names.append(hero.hero_name)
			hero.is_on_mission = false
			hero.current_mission_id = ""
			hero.add_experience(result.exp)
			
			# Apply damage risk
			if randf() < mission.damage_risk:
				var damage = randf_range(10, 30)
				hero.take_damage(damage)
	
	# Create story-based result message
	var story_message = _generate_mission_story(mission, result, hero_names)
	
	# Show detailed result in status (won't be covered by autosave)
	if status_label:
		status_label.text = story_message
	
	# Also print to console for full details
	print("=== MISSION COMPLETE ===")
	print(story_message)
	print("=======================")
	
	mission_completed.emit(mission, result)
	active_missions.erase(mission)

func _generate_mission_story(mission: Mission, result: Dictionary, hero_names: Array) -> String:
	var heroes_text = ""
	if hero_names.size() == 1:
		heroes_text = hero_names[0]
	elif hero_names.size() == 2:
		heroes_text = hero_names[0] + " and " + hero_names[1]
	else:
		heroes_text = ", ".join(hero_names.slice(0, -1)) + ", and " + hero_names[-1]
	
	var story = ""
	
	if result.success:
		# Success stories based on mission type
		match mission.mission_name:
			"Cat Rescue":
				story = "✅ %s successfully rescued the cat from the tree! The grateful owner rewarded them. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Bank Robbery":
				story = "✅ %s stopped the bank robbery! The criminals have been apprehended and the money secured. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Hostage Crisis":
				story = "✅ %s rescued all hostages safely! The building was secured without casualties. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Cyber Attack":
				story = "✅ %s thwarted the cyber attack! City data has been secured and hackers traced. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Super Villain":
				story = "✅ %s defeated the villain! Dr. Chaos has been captured and imprisoned. The city is safe! (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Bomb Threat":
				story = "✅ %s defused all bombs with seconds to spare! Countless lives were saved. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Investigation":
				story = "✅ %s solved the mystery! The missing person has been found safe and sound. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Fire Rescue":
				story = "✅ %s evacuated the building and extinguished the flames! Everyone made it out safely. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Gang War":
				story = "✅ %s stopped the gang war! Peace has been restored to the streets. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Lost Pet":
				story = "✅ %s found the lost puppy! The family is overjoyed to be reunited. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Alien Invasion":
				story = "✅ %s repelled the alien invaders! Earth is safe once more. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Bridge Collapse":
				story = "✅ %s rescued everyone from the collapsing bridge! All civilians evacuated safely. (+$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			_:
				story = "✅ SUCCESS! %s completed %s! (+$%d 💰 +%d ⭐)" % [heroes_text, mission.mission_name, result.money, result.fame]
	else:
		# Failure stories
		match mission.mission_name:
			"Cat Rescue":
				story = "❌ The cat escaped to another tree... %s tried their best. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Bank Robbery":
				story = "❌ The robbers escaped with some cash, but %s prevented greater losses. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Hostage Crisis":
				story = "❌ Some hostages were injured during the rescue. %s did what they could. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Cyber Attack":
				story = "❌ Some data was stolen before %s could stop the hackers. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Super Villain":
				story = "❌ Dr. Chaos escaped! %s fought valiantly but the villain got away. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Bomb Threat":
				story = "❌ One bomb detonated causing minor damage. %s defused the rest in time. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Investigation":
				story = "❌ The trail went cold... %s needs more clues to solve this case. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Fire Rescue":
				story = "❌ The fire spread faster than expected. %s saved most people but some were injured. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Gang War":
				story = "❌ The gangs scattered before %s could apprehend them all. The conflict continues. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Lost Pet":
				story = "❌ The puppy ran off again! %s will keep searching. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Alien Invasion":
				story = "❌ The aliens retreated but will return... %s bought us time. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			"Bridge Collapse":
				story = "❌ Not everyone made it off in time. %s saved as many as they could. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, result.money, result.fame]
			_:
				story = "❌ FAILED! %s couldn't complete %s. (Partial: +$%d 💰 +%d ⭐)" % [heroes_text, mission.mission_name, result.money, result.fame]
	
	return story

func get_hero_by_id(id: String) -> Hero:
	for hero in heroes:
		if hero.hero_id == id:
			return hero
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
