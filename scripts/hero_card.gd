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

# Signals
signal hero_selected(hero: Hero, mission: Mission)
signal hero_deselected(hero: Hero, mission: Mission)

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)

func setup(hero: Hero, mission: Mission = null) -> void:
	hero_data = hero
	current_mission = mission
	update_display()

func update_display() -> void:
	if not hero_data:
		return
	
	# Basic info
	name_label.text = "%s %s" % [hero_data.hero_emoji, hero_data.hero_name]
	level_label.text = "Lv.%d" % hero_data.level
	
	# Stats
	strength_label.text = "💪 STR: %d" % hero_data.get_total_strength()
	speed_label.text = "⚡ SPD: %d" % hero_data.get_total_speed()
	intelligence_label.text = "🧠 INT: %d" % hero_data.get_total_intelligence()
	
	# Specialties
	specialty_label.text = JSON.stringify(hero_data.get_specialties())
	 
	# Health and stamina bars
	health_bar.max_value = hero_data.max_health
	health_bar.value = hero_data.current_health
	
	stamina_bar.max_value = hero_data.max_stamina
	stamina_bar.value = hero_data.current_stamina
	
	# Status
	status_text_label.text = hero_data.get_status_text()
	
	# Button state
	if hero_data.is_available() and current_mission and not current_mission.is_active:
		select_button.disabled = false
		if selected_for_mission:
			select_button.text = "✓ SELECTED"
			modulate = Color(0.7, 1.0, 0.7)
		else:
			select_button.text = "SELECT FOR MISSION"
			modulate = Color.WHITE
	else:
		select_button.disabled = true
		if hero_data.is_on_mission:
			select_button.text = "ON MISSION"
		elif hero_data.is_recovering:
			select_button.text = "RECOVERING"
		else:
			select_button.text = "UNAVAILABLE"
		modulate = Color(0.5, 0.5, 0.5)

func _on_select_pressed() -> void:
	if not hero_data or not current_mission:
		return
	
	selected_for_mission = !selected_for_mission
	
	if selected_for_mission:
		hero_selected.emit(hero_data, current_mission)
	else:
		hero_deselected.emit(hero_data, current_mission)
	
	update_display()

func deselect() -> void:
	selected_for_mission = false
	update_display()
