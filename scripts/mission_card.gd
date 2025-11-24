# res://scripts/mission_card.gd
extends PanelContainer

# UI References
@onready var mission_name_label: Label = $MarginContainer/VBoxContainer/TitleRow/MissionNameLabel
@onready var difficulty_label: Label = $MarginContainer/VBoxContainer/TitleRow/DifficultyLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var money_reward_label: Label = $MarginContainer/VBoxContainer/RewardsRow/MoneyRewardLabel
@onready var fame_reward_label: Label = $MarginContainer/VBoxContainer/RewardsRow/FameRewardLabel
@onready var requirements_label: Label = $MarginContainer/VBoxContainer/RequirementsLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TimerRow/TimerLabel
@onready var timer_progress: ProgressBar = $MarginContainer/VBoxContainer/TimerRow/TimerProgress
@onready var assigned_heroes_label: Label = $MarginContainer/VBoxContainer/AssignedHeroesRow/AssignedHeroesLabel
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton

# Data
var mission_data: Mission
var game_manager: Node

# Signals
signal mission_selected(mission: Mission)
signal mission_started(mission: Mission)

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _process(delta: float) -> void:
	if mission_data and mission_data.is_active:
		update_timer_display()

func setup(mission: Mission, gm: Node) -> void:
	mission_data = mission
	game_manager = gm
	update_display()

func update_display() -> void:
	if not mission_data:
		return
	
	# Mission info
	mission_name_label.text = "%s %s" % [mission_data.mission_emoji, mission_data.mission_name]
	difficulty_label.text = mission_data.get_difficulty_string()
	difficulty_label.add_theme_color_override("font_color", mission_data.get_difficulty_color())
	description_label.text = mission_data.description
	
	# Rewards
	money_reward_label.text = "💰 $%d" % mission_data.money_reward
	fame_reward_label.text = "⭐ %d Fame" % mission_data.fame_reward
	
	# Requirements
	requirements_label.text = mission_data.get_requirements_text()
	
	# Assigned heroes
	if mission_data.assigned_hero_ids.size() > 0:
		var hero_names = []
		for hero_id in mission_data.assigned_hero_ids:
			var hero = game_manager.get_hero_by_id(hero_id)
			if hero:
				hero_names.append(hero.hero_name)
		assigned_heroes_label.text = "👥 Assigned: %s" % ", ".join(hero_names)
	else:
		assigned_heroes_label.text = "👥 No heroes assigned"
	
	# Timer and button state
	if mission_data.is_active:
		timer_label.visible = true
		timer_progress.visible = true
		start_button.visible = false
		update_timer_display()
	elif mission_data.is_completed:
		timer_label.visible = false
		timer_progress.visible = false
		start_button.text = "COMPLETED"
		start_button.disabled = true
		modulate = Color(0.5, 0.5, 0.5)
	else:
		timer_label.visible = false
		timer_progress.visible = false
		start_button.visible = true
		start_button.disabled = not mission_data.can_start()
		if mission_data.can_start():
			start_button.text = "🚀 START MISSION"
		else:
			start_button.text = "ASSIGN HEROES FIRST"

func update_timer_display() -> void:
	if not mission_data or not mission_data.is_active:
		return
	
	var minutes = int(mission_data.time_remaining) / 60
	var seconds = int(mission_data.time_remaining) % 60
	timer_label.text = "⏱️ Time: %02d:%02d" % [minutes, seconds]
	
	timer_progress.max_value = mission_data.base_duration
	timer_progress.value = mission_data.base_duration - mission_data.time_remaining

func _on_start_pressed() -> void:
	if mission_data:
		mission_started.emit(mission_data)
