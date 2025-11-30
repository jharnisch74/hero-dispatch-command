# res://scripts/game_manager_rapid.gd
# Simplified game manager for Rapid Response system
extends Node

# Resources
var money: int = 500
var fame: int = 0

# Collections
var heroes: Array[Hero] = []
var active_missions: Array[Mission] = []  # For chaos system compatibility

# Systems
var chaos_system: ChaosSystem
var recruitment_system: RecruitmentSystem
var rapid_manager: RapidResponseManager  # Set by main

# UI References
var money_label: Label
var fame_label: Label

# Signals
signal money_changed(new_amount: int)
signal fame_changed(new_amount: int)
signal hero_updated(hero: Hero)
signal heroes_changed()

func _ready() -> void:
	_initialize_chaos_system()
	_initialize_recruitment_system()
	_initialize_starting_heroes()

func _initialize_chaos_system() -> void:
	chaos_system = ChaosSystem.new(self)
	add_child(chaos_system)
	
	# Connect signals
	chaos_system.chaos_level_changed.connect(_on_chaos_level_changed)
	chaos_system.chaos_threshold_crossed.connect(_on_chaos_threshold_crossed)
	chaos_system.crisis_event_triggered.connect(_on_crisis_event_triggered)

func _initialize_recruitment_system() -> void:
	recruitment_system = RecruitmentSystem.new(self)
	add_child(recruitment_system)

func _initialize_starting_heroes() -> void:
	if heroes.size() > 0:
		print("Heroes already loaded")
		return
	
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
		
		# Boost starter heroes
		hero.base_strength += 2
		hero.base_speed += 2
		hero.base_intelligence += 2
		
		heroes.append(hero)
		print("  Created hero: %s" % hero.hero_name)

func _process(delta: float) -> void:
	_update_heroes(delta)
	_sync_active_missions()  # Keep active_missions in sync with rapid_manager

func _update_heroes(delta: float) -> void:
	for hero in heroes:
		hero.update_recovery(delta)
		hero.regen_stamina(delta)
		hero_updated.emit(hero)

func _sync_active_missions() -> void:
	"""Sync active_missions with rapid_manager for chaos system compatibility"""
	if not rapid_manager:
		return
	
	# Build list of active missions from rapid manager slots
	active_missions.clear()
	for slot in rapid_manager.active_slots:
		if slot.has("mission"):
			active_missions.append(slot.mission)

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
	print("Status: %s" % text)

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

func get_hero_by_id(id: String) -> Hero:
	for hero in heroes:
		if hero.hero_id == id:
			return hero
	return null

# Chaos System Signal Handlers
func _on_chaos_level_changed(_zone: String, _new_level: float) -> void:
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
