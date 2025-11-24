# res://scenes/main.gd
# UPDATED VERSION WITH MISSION MAP
# Replace your existing main.gd with this

extends Control

# UI Node References
@onready var hero_list: VBoxContainer = $MainMargin/MainLayout/ContentSplit/HeroPanel/VBoxContainer/HeroScroll/HeroList
@onready var mission_container: Control = $MainMargin/MainLayout/ContentSplit/MissionPanel/VBoxContainer/MissionMapContainer
@onready var money_label: Label = $MainMargin/MainLayout/HeaderPanel/HBoxContainer/ResourceDisplay/MoneyLabel
@onready var fame_label: Label = $MainMargin/MainLayout/HeaderPanel/HBoxContainer/ResourceDisplay/FameLabel
@onready var status_label: Label = $MainMargin/MainLayout/BottomPanel/HBoxContainer/StatusLabel
@onready var upgrade_button: Button = $MainMargin/MainLayout/BottomPanel/HBoxContainer/UpgradeButton

# Scenes
var hero_card_scene = preload("res://scenes/ui/hero_card.tscn")
var upgrade_panel_scene = preload("res://scenes/ui/upgrade_panel.tscn")

# Game Manager
var game_manager: Node

# Save Manager
var save_manager: Node

# Mission Map
var mission_map: Control

# Upgrade Panel
var upgrade_panel: CanvasLayer

# Currently selected mission for hero assignment
var selected_mission: Mission = null

func _ready() -> void:
	_initialize_game_manager()
	_initialize_save_manager()
	_initialize_mission_map()
	_setup_upgrade_panel()
	_setup_ui_connections()
	
	# Try to load save, if it fails, create new game
	if not save_manager.load_game():
		_initial_ui_update()
	else:
		# Save was loaded, refresh UI
		_refresh_hero_list()
		mission_map.refresh_missions()

func _notification(what: int) -> void:
	# Auto-save when closing the game
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_manager:
			save_manager.save_game()
		get_tree().quit()

func _initialize_game_manager() -> void:
	game_manager = Node.new()
	game_manager.name = "GameManager"
	game_manager.set_script(preload("res://scripts/game_manager.gd"))
	add_child(game_manager)
	
	# Connect references
	game_manager.hero_list_container = hero_list
	game_manager.money_label = money_label
	game_manager.fame_label = fame_label
	game_manager.status_label = status_label
	
	# Connect signals
	game_manager.hero_updated.connect(_on_hero_updated)
	game_manager.mission_completed.connect(_on_mission_completed)

func _initialize_save_manager() -> void:
	save_manager = Node.new()
	save_manager.name = "SaveManager"
	save_manager.set_script(preload("res://scripts/save_manager.gd"))
	add_child(save_manager)
	
	# Give save manager reference to game manager
	save_manager.set_game_manager(game_manager)

func _initialize_mission_map() -> void:
	mission_map = Control.new()
	mission_map.name = "MissionMap"
	mission_map.set_script(preload("res://scripts/mission_map.gd"))
	mission_container.add_child(mission_map)
	
	mission_map.setup(game_manager)
	mission_map.mission_clicked.connect(_on_map_mission_clicked)
	mission_map.mission_started.connect(_on_mission_start_requested)

func _setup_upgrade_panel() -> void:
	upgrade_panel = upgrade_panel_scene.instantiate()
	add_child(upgrade_panel)

func _setup_ui_connections() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

func _initial_ui_update() -> void:
	money_label.text = "💰 Money: $%d" % game_manager.money
	fame_label.text = "⭐ Fame: %d" % game_manager.fame
	_refresh_hero_list()
	mission_map.refresh_missions()

func _process(_delta: float) -> void:
	# Only update detail panel if it exists and is visible
	if mission_map and mission_map.mission_detail_panel and mission_map.mission_detail_panel.visible:
		if mission_map.selected_mission and mission_map.selected_mission.is_active:
			mission_map._update_timer_display()

func _refresh_hero_list(for_mission: Mission = null) -> void:
	# Clear existing cards
	for child in hero_list.get_children():
		child.queue_free()
	
	# Create hero cards
	for hero in game_manager.heroes:
		var card = hero_card_scene.instantiate()
		hero_list.add_child(card)
		card.setup(hero, for_mission if for_mission else selected_mission)
		card.hero_selected.connect(_on_hero_selected)
		card.hero_deselected.connect(_on_hero_deselected)

func _on_map_mission_clicked(mission: Mission) -> void:
	if not mission.is_active and not mission.is_completed:
		selected_mission = mission
		_refresh_hero_list(mission)
		game_manager.update_status("📋 Select heroes for: %s" % mission.mission_name)

func _on_hero_selected(hero: Hero, mission: Mission) -> void:
	if game_manager.assign_hero_to_mission(hero, mission):
		mission_map.refresh_missions()

func _on_hero_deselected(hero: Hero, mission: Mission) -> void:
	if game_manager.unassign_hero_from_mission(hero, mission):
		mission_map.refresh_missions()

func _on_mission_start_requested(mission: Mission) -> void:
	if game_manager.start_mission(mission):
		selected_mission = null
		_refresh_hero_list()
		mission_map.refresh_missions()
		mission_map.close_detail_panel()

func _on_hero_updated(_hero: Hero) -> void:
	# Heroes are updated in real-time via the game manager
	pass

func _on_mission_completed(_mission: Mission, _result: Dictionary) -> void:
	_refresh_hero_list()
	# Only refresh missions when one completes
	mission_map.refresh_missions()
	
	# Save after important events
	save_manager.save_game()

func _on_upgrade_button_pressed() -> void:
	upgrade_panel.show_panel(game_manager)
