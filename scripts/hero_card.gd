# res://scripts/hero_card.gd
extends PanelContainer

# UI References
@onready var name_label: Label = $MarginContainer/VBoxContainer/TopRow/NameLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopRow/LevelLabel
@onready var strength_label: Label = $MarginContainer/VBoxContainer/StatsRow/LeftStats/StrengthLabel
@onready var speed_label: Label = $MarginContainer/VBoxContainer/StatsRow/LeftStats/SpeedLabel
@onready var intelligence_label: Label = $MarginContainer/VBoxContainer/StatsRow/LeftStats/IntelligenceLabel
@onready var specialty_label: Label = $MarginContainer/VBoxContainer/StatsRow/CenterStats/SpecialtyList
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/StatsRow/RightStats/HealthBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StatsRow/RightStats/StaminaBar
@onready var status_text_label: Label = $MarginContainer/VBoxContainer/StatsRow/RightStats/StatusTextLabel
@onready var select_button: Button = $MarginContainer/VBoxContainer/SelectButton

# Data
var hero_data: Hero
var selected_for_mission: bool = false
var current_mission: Mission
var game_manager: Node  # Need reference to check other mission assignments

# Signals
signal hero_selected(hero: Hero, mission: Mission)
signal hero_deselected(hero: Hero, mission: Mission)

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	print("HeroCard _ready() called")

func setup(hero: Hero, mission: Mission = null, gm: Node = null) -> void:
	print("\n=== HERO CARD SETUP ===")
	print("  Hero: %s" % (hero.hero_name if hero else "NULL"))
	print("  Mission: %s" % (mission.mission_name if mission else "NULL"))
	
	hero_data = hero
	current_mission = mission
	game_manager = gm
	
	# Check if hero is already assigned to this mission
	if mission and hero.hero_id in mission.assigned_hero_ids:
		selected_for_mission = true
		print("  Hero is ALREADY ASSIGNED to this mission")
	else:
		selected_for_mission = false
		print("  Hero is NOT assigned to this mission")
	
	print("======================\n")
	update_display()

func update_display() -> void:
	if not hero_data:
		print("ERROR: update_display called but hero_data is NULL!")
		return
	
	print("\n--- Updating Hero Card: %s ---" % hero_data.hero_name)
	
	# Basic info
	name_label.text = "%s %s" % [hero_data.hero_emoji, hero_data.hero_name]
	level_label.text = "Lv.%d" % hero_data.level
	
	# Stats
	strength_label.text = "💪 STR: %d" % hero_data.get_total_strength()
	speed_label.text = "⚡ SPD: %d" % hero_data.get_total_speed()
	intelligence_label.text = "🧠 INT: %d" % hero_data.get_total_intelligence()
	
	# Specialties
	var spec_names = []
	for spec in hero_data.get_specialties():
		match spec:
			Hero.Specialty.COMBAT:
				spec_names.append("⚔️Combat")
			Hero.Specialty.SPEED:
				spec_names.append("⚡Speed")
			Hero.Specialty.TECH:
				spec_names.append("💻Tech")
			Hero.Specialty.RESCUE:
				spec_names.append("🚑Rescue")
			Hero.Specialty.INVESTIGATION:
				spec_names.append("🔍Investigation")
	specialty_label.text = ", ".join(spec_names) if spec_names.size() > 0 else "None"
	 
	# Health and stamina bars
	health_bar.max_value = hero_data.max_health
	health_bar.value = hero_data.current_health
	
	stamina_bar.max_value = hero_data.max_stamina
	stamina_bar.value = hero_data.current_stamina
	
	# Status
	status_text_label.visible = true
	status_text_label.text = hero_data.get_status_text()
	
	# Debug hero state
	print("  is_available: %s" % hero_data.is_available())
	print("  is_on_mission: %s" % hero_data.is_on_mission)
	print("  is_recovering: %s" % hero_data.is_recovering)
	print("  health: %.1f/%.1f" % [hero_data.current_health, hero_data.max_health])
	print("  stamina: %.1f/%.1f" % [hero_data.current_stamina, hero_data.max_stamina])
	print("  current_mission: %s" % (current_mission.mission_name if current_mission else "None"))
	print("  selected_for_mission: %s" % selected_for_mission)
	
	# DETAILED BUTTON STATE LOGIC
	var button_should_be_enabled = false
	var button_text = "UNAVAILABLE"
	var card_color = Color.WHITE
	
	# Check each condition
	if hero_data.is_on_mission:
		print("  → Button DISABLED: Hero on mission")
		button_should_be_enabled = false
		button_text = "🚀 ON MISSION"
		card_color = Color(0.7, 0.7, 0.9)
	elif hero_data.is_recovering:
		print("  → Button DISABLED: Hero recovering")
		button_should_be_enabled = false
		button_text = "💤 RECOVERING"
		card_color = Color(0.6, 0.6, 0.6)
	elif hero_data.current_health <= 0:
		print("  → Button DISABLED: Hero defeated")
		button_should_be_enabled = false
		button_text = "💀 DEFEATED"
		card_color = Color(0.5, 0.5, 0.5)
	elif hero_data.current_stamina < 20:
		print("  → Button DISABLED: Hero exhausted")
		button_should_be_enabled = false
		button_text = "😓 EXHAUSTED"
		card_color = Color(0.7, 0.7, 0.5)
	elif not current_mission:
		print("  → Button DISABLED: No mission context")
		button_should_be_enabled = false
		
		# Even without a mission context, check if hero is assigned to ANY mission
		var assigned_mission = null
		if game_manager and game_manager.has_method("is_hero_assigned_to_mission"):
			assigned_mission = game_manager.is_hero_assigned_to_mission(hero_data.hero_id)
		
		if assigned_mission:
			button_text = "ASSIGNED TO %s" % assigned_mission.mission_name.to_upper()
			card_color = Color(0.8, 0.7, 0.5)
		else:
			button_text = "SELECT A MISSION FIRST"
			card_color = Color(0.7, 0.7, 0.7)
	elif current_mission.is_active:
		print("  → Button DISABLED: Mission already active")
		button_should_be_enabled = false
		button_text = "MISSION ACTIVE"
		card_color = Color(0.7, 0.7, 0.7)
	elif current_mission.is_completed:
		print("  → Button DISABLED: Mission completed")
		button_should_be_enabled = false
		button_text = "COMPLETED"
		card_color = Color(0.5, 0.5, 0.5)
	else:
		# Check if hero is assigned to a different mission
		var assigned_mission = null
		if game_manager and game_manager.has_method("is_hero_assigned_to_mission"):
			assigned_mission = game_manager.is_hero_assigned_to_mission(hero_data.hero_id)
		
		if assigned_mission and assigned_mission.mission_id != current_mission.mission_id:
			print("  → Button DISABLED: Hero assigned to another mission (%s)" % assigned_mission.mission_name)
			button_should_be_enabled = false
			button_text = "ASSIGNED TO %s" % assigned_mission.mission_name.to_upper()
			card_color = Color(0.8, 0.7, 0.5)
		else:
			print("  → Button ENABLED: Hero available for selection")
			button_should_be_enabled = true
			if selected_for_mission:
				button_text = "✓ SELECTED"
				card_color = Color(0.7, 1.0, 0.7)
			else:
				button_text = "SELECT FOR MISSION"
				card_color = Color.WHITE
	
	# Apply button state
	select_button.disabled = not button_should_be_enabled
	select_button.text = button_text
	modulate = card_color
	
	print("  FINAL: Button enabled=%s, text='%s'" % [button_should_be_enabled, button_text])
	print("--- End Card Update ---\n")

func _on_select_pressed() -> void:
	print("\n!!! SELECT BUTTON PRESSED !!!")
	print("  Hero: %s" % hero_data.hero_name)
	print("  Current Mission: %s" % (current_mission.mission_name if current_mission else "None"))
	print("  Was selected: %s" % selected_for_mission)
	
	if not hero_data or not current_mission:
		print("  ERROR: Missing hero_data or current_mission!")
		return
	
	# Don't allow toggling if hero isn't available
	if not hero_data.is_available():
		print("  ERROR: Hero is not available!")
		return
	
	# Don't allow toggling if mission is active or completed
	if current_mission.is_active or current_mission.is_completed:
		print("  ERROR: Mission is active or completed!")
		return
	
	selected_for_mission = !selected_for_mission
	print("  Now selected: %s" % selected_for_mission)
	
	if selected_for_mission:
		print("  → Emitting hero_selected signal")
		hero_selected.emit(hero_data, current_mission)
	else:
		print("  → Emitting hero_deselected signal")
		hero_deselected.emit(hero_data, current_mission)
	
	print("!!! END SELECT PRESSED !!!\n")
	update_display()

func deselect() -> void:
	selected_for_mission = false
	update_display()
