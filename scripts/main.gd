# res://scripts/main.gd
extends Control

# UI Node References
@onready var hero_list: VBoxContainer = $MainMargin/MainLayout/ContentSplit/HeroPanel/VBoxContainer/HeroScroll/HeroList
@onready var hero_panel_title: Label = $MainMargin/MainLayout/ContentSplit/HeroPanel/VBoxContainer/HeroPanelTitle
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
	
	# Wait for UI to be laid out properly
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Try to load save, if it fails, create new game
	if not save_manager.load_game():
		await _initial_ui_update()
	else:
		# Save was loaded, refresh UI
		await _refresh_hero_list()
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
	
	print("Connecting mission map signals...")
	mission_map.mission_clicked.connect(_on_map_mission_clicked)
	mission_map.mission_started.connect(_on_mission_start_requested)
	print("Mission map signals connected!")
	print("  mission_clicked signal exists: %s" % mission_map.has_signal("mission_clicked"))
	print("  mission_started signal exists: %s" % mission_map.has_signal("mission_started"))

func _setup_upgrade_panel() -> void:
	upgrade_panel = upgrade_panel_scene.instantiate()
	add_child(upgrade_panel)

func _setup_ui_connections() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

func _initial_ui_update() -> void:
	money_label.text = "💰 Money: $%d" % game_manager.money
	fame_label.text = "⭐ Fame: %d" % game_manager.fame
	_update_hero_panel_title()
	await _refresh_hero_list()  # Wait for hero list to finish
	await get_tree().process_frame  # Extra frame for layout
	mission_map.refresh_missions()

func _process(_delta: float) -> void:
	# Update timer display in mission detail panel
	if mission_map and mission_map.mission_detail_panel and mission_map.mission_detail_panel.visible:
		if mission_map.selected_mission and mission_map.selected_mission.is_active:
			mission_map._update_timer_display()

func _update_hero_panel_title() -> void:
	if selected_mission:
		hero_panel_title.text = "SELECT HEROES FOR:\n%s %s" % [selected_mission.mission_emoji, selected_mission.mission_name]
		hero_panel_title.add_theme_color_override("font_color", Color("#ffcc00"))
	else:
		hero_panel_title.text = "YOUR HEROES"
		hero_panel_title.add_theme_color_override("font_color", Color("#00d9ff"))

func _refresh_hero_list(for_mission: Mission = null) -> void:
	print("\n*** _refresh_hero_list called ***")
	print("  for_mission parameter: %s" % (for_mission.mission_name if for_mission else "NULL"))
	print("  selected_mission: %s" % (selected_mission.mission_name if selected_mission else "NULL"))
	
	# Clear existing cards
	for child in hero_list.get_children():
		child.queue_free()
	
	var mission_to_use = for_mission if for_mission else selected_mission
	print("  mission_to_use: %s" % (mission_to_use.mission_name if mission_to_use else "NULL"))
	
	# Update title
	_update_hero_panel_title()
	
	# Create hero cards
	print("  Creating %d hero cards..." % game_manager.heroes.size())
	var cards = []
	for hero in game_manager.heroes:
		var card = hero_card_scene.instantiate()
		hero_list.add_child(card)
		cards.append(card)
		card.hero_selected.connect(_on_hero_selected)
		card.hero_deselected.connect(_on_hero_deselected)
	
	# Wait one frame for all cards to be in tree, then setup
	await get_tree().process_frame
	
	for i in range(cards.size()):
		var card = cards[i]
		var hero = game_manager.heroes[i]
		print("    → Calling setup for hero: %s with mission: %s" % [hero.hero_name, mission_to_use.mission_name if mission_to_use else "NULL"])
		card.setup(hero, mission_to_use, game_manager)
	
	print("*** _refresh_hero_list complete ***\n")

func _on_map_mission_clicked(mission: Mission) -> void:
	print("\n================================================================")
	print("MAP MISSION CLICKED")
	print("  Mission: %s" % mission.mission_name)
	print("  Is Active: %s" % mission.is_active)
	print("  Is Completed: %s" % mission.is_completed)
	print("================================================================\n")
	
	if mission.is_active:
		game_manager.update_status("⏱️ Mission in progress: %s" % mission.mission_name)
		selected_mission = null
		_refresh_hero_list()  # Don't await - fire and forget
		return
	
	if mission.is_completed:
		game_manager.update_status("✅ Mission already completed: %s" % mission.mission_name)
		selected_mission = null
		_refresh_hero_list()  # Don't await - fire and forget
		return
	
	# Mission is available for assignment
	selected_mission = mission
	
	# Refresh hero list
	_refresh_hero_list(mission)  # Don't await - fire and forget
	
	var assigned_count = mission.assigned_hero_ids.size()
	var max_heroes = mission.max_heroes
	
	if assigned_count > 0:
		game_manager.update_status("📋 %s - %d/%d heroes assigned. Select more or start mission!" % [mission.mission_name, assigned_count, max_heroes])
	else:
		game_manager.update_status("📋 Mission selected: %s - Select up to %d heroes!" % [mission.mission_name, max_heroes])
	
	print("  ✅ Selected mission for hero assignment. Max heroes: %d" % max_heroes)

func _on_hero_selected(hero: Hero, mission: Mission) -> void:
	print("🦸 Hero selected: %s for mission: %s" % [hero.hero_name, mission.mission_name])
	
	if game_manager.assign_hero_to_mission(hero, mission):
		# Refresh hero list to show updated selection states
		_refresh_hero_list(mission)
		mission_map.refresh_missions()
		mission_map.refresh_detail_panel()  # Immediately update detail panel
		
		var assigned_count = mission.assigned_hero_ids.size()
		game_manager.update_status("✅ %s assigned! (%d/%d heroes)" % [hero.hero_name, assigned_count, mission.max_heroes])
	else:
		# Refresh to deselect the hero card
		_refresh_hero_list(mission)

func _on_hero_deselected(hero: Hero, mission: Mission) -> void:
	print("🔄 Hero deselected: %s from mission: %s" % [hero.hero_name, mission.mission_name])
	
	if game_manager.unassign_hero_from_mission(hero, mission):
		_refresh_hero_list(mission)
		mission_map.refresh_missions()
		mission_map.refresh_detail_panel()  # Immediately update detail panel
		
		var assigned_count = mission.assigned_hero_ids.size()
		game_manager.update_status("🔄 %s removed (%d/%d heroes)" % [hero.hero_name, assigned_count, mission.max_heroes])

func _on_mission_start_requested(mission: Mission) -> void:
	print("🚀 Starting mission: %s" % mission.mission_name)
	
	if game_manager.start_mission(mission):
		selected_mission = null
		_refresh_hero_list()
		mission_map.refresh_missions()
		mission_map.close_detail_panel()
	else:
		# Keep mission selected if start failed
		_refresh_hero_list(mission)

func _on_hero_updated(_hero: Hero) -> void:
	# Only refresh periodically, not every frame
	pass

func _on_mission_completed(_mission: Mission, _result: Dictionary) -> void:
	# Clear selection if the completed mission was selected
	if selected_mission and selected_mission.mission_id == _mission.mission_id:
		selected_mission = null
	
	_refresh_hero_list()
	mission_map.refresh_missions()
	
	# Save after important events
	save_manager.save_game()

func _on_upgrade_button_pressed() -> void:
	upgrade_panel.show_panel(game_manager)
