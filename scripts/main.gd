extends Control

func _input(event: InputEvent) -> void:
	# Debug hotkey: Press F9 to force reset all hero availability
	if event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_F9):
		game_manager.force_reset_all_heroes()
		_refresh_hero_list(selected_mission)
	
	# Debug hotkey: Press F8 to delete save and restart
	if Input.is_key_pressed(KEY_F8):
		game_manager.delete_save_and_restart()
		selected_mission = null
		_refresh_hero_list()
		mission_map.refresh_missions()# res://scripts/main.gd

# UI Node References
@onready var hero_list: VBoxContainer = $MainMargin/MainLayout/ContentSplit/HeroPanel/VBoxContainer/HeroScroll/HeroList
@onready var hero_panel_title: Label = $MainMargin/MainLayout/ContentSplit/HeroPanel/VBoxContainer/HeroPanelTitle
@onready var mission_container: Control = $MainMargin/MainLayout/ContentSplit/MissionPanel/VBoxContainer/MissionMapContainer
@onready var money_label: Label = $MainMargin/MainLayout/HeaderPanel/HBoxContainer/ResourceDisplay/MoneyLabel
@onready var fame_label: Label = $MainMargin/MainLayout/HeaderPanel/HBoxContainer/ResourceDisplay/FameLabel
@onready var status_label: Label = $MainMargin/MainLayout/BottomPanel/HBoxContainer/StatusLabel
@onready var upgrade_button: Button = $MainMargin/MainLayout/BottomPanel/HBoxContainer/UpgradeButton

# Recruitment Button (we'll add it to the scene)
var recruit_button: Button

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

# Recruitment Panel
var recruitment_panel: CanvasLayer

# Currently selected mission for hero assignment
var selected_mission: Mission = null

func _ready() -> void:
	_initialize_game_manager()
	_initialize_save_manager()
	_initialize_mission_map()
	_setup_upgrade_panel()
	_setup_recruitment_panel()
	_setup_ui_connections()
	
	# Wait for UI to be laid out properly
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Try to load save, if it fails, create new game
	if not save_manager.load_game():
		await _initial_ui_update()
	else:
		# Save was loaded, refresh UI
		await _refresh_hero_list()
		await get_tree().process_frame
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
	game_manager.heroes_changed.connect(_on_heroes_changed)

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

func _setup_upgrade_panel() -> void:
	upgrade_panel = upgrade_panel_scene.instantiate()
	add_child(upgrade_panel)

func _setup_recruitment_panel() -> void:
	recruitment_panel = CanvasLayer.new()
	recruitment_panel.name = "RecruitmentPanel"
	recruitment_panel.set_script(preload("res://scripts/recruitment_panel.gd"))
	add_child(recruitment_panel)
	
	# Setup after it's in the tree
	await get_tree().process_frame
	recruitment_panel.setup(game_manager, game_manager.recruitment_system)

func _setup_ui_connections() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	
	# Create recruit button dynamically
	var bottom_hbox = $MainMargin/MainLayout/BottomPanel/HBoxContainer
	recruit_button = Button.new()
	recruit_button.text = "🎰 RECRUIT HEROES"
	recruit_button.custom_minimum_size = Vector2(200, 0)
	recruit_button.add_theme_font_size_override("font_size", 18)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#9c27b0")
	btn_style.set_corner_radius_all(5)
	recruit_button.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color("#7b1fa2")
	btn_hover.set_corner_radius_all(5)
	recruit_button.add_theme_stylebox_override("hover", btn_hover)
	
	recruit_button.pressed.connect(_on_recruit_button_pressed)
	
	# Add after upgrade button
	bottom_hbox.add_child(recruit_button)
	bottom_hbox.move_child(recruit_button, 1)

func _initial_ui_update() -> void:
	money_label.text = "💰 Money: $%d" % game_manager.money
	fame_label.text = "⭐ Fame: %d" % game_manager.fame
	_update_hero_panel_title()
	await _refresh_hero_list()
	await get_tree().process_frame
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
	
	# Clear existing cards
	for child in hero_list.get_children():
		child.queue_free()
	
	var mission_to_use = for_mission if for_mission else selected_mission
	
	# Update title
	_update_hero_panel_title()
	
	# Create hero cards
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
		card.setup(hero, mission_to_use, game_manager)

func _on_map_mission_clicked(mission: Mission) -> void:
	print("\n================================================================")
	print("MAP MISSION CLICKED")
	print("  Mission: %s" % mission.mission_name)
	print("================================================================\n")
	
	if mission.is_active:
		game_manager.update_status("⏱️ Mission in progress: %s" % mission.mission_name)
		selected_mission = null
		_refresh_hero_list()
		return
	
	if mission.is_completed:
		game_manager.update_status("✅ Mission already completed: %s" % mission.mission_name)
		selected_mission = null
		_refresh_hero_list()
		return
	
	# Mission is available for assignment
	selected_mission = mission
	
	# Refresh hero list
	_refresh_hero_list(mission)
	
	var assigned_count = mission.assigned_hero_ids.size()
	var max_heroes = mission.max_heroes
	
	if assigned_count > 0:
		game_manager.update_status("📋 %s - %d/%d heroes assigned. Select more or start mission!" % [mission.mission_name, assigned_count, max_heroes])
	else:
		game_manager.update_status("📋 Mission selected: %s - Select up to %d heroes!" % [mission.mission_name, max_heroes])

func _on_hero_selected(hero: Hero, mission: Mission) -> void:
	print("🦸 Hero selected: %s for mission: %s" % [hero.hero_name, mission.mission_name])
	
	if game_manager.assign_hero_to_mission(hero, mission):
		_refresh_hero_list(mission)
		mission_map.refresh_missions()
		mission_map.refresh_detail_panel()
		
		var assigned_count = mission.assigned_hero_ids.size()
		game_manager.update_status("✅ %s assigned! (%d/%d heroes)" % [hero.hero_name, assigned_count, mission.max_heroes])
	else:
		_refresh_hero_list(mission)

func _on_hero_deselected(hero: Hero, mission: Mission) -> void:
	print("🔄 Hero deselected: %s from mission: %s" % [hero.hero_name, mission.mission_name])
	
	if game_manager.unassign_hero_from_mission(hero, mission):
		_refresh_hero_list(mission)
		mission_map.refresh_missions()
		mission_map.refresh_detail_panel()
		
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

func _on_recruit_button_pressed() -> void:
	recruitment_panel.show_panel()

func _on_heroes_changed() -> void:
	# Refresh hero list when new heroes are recruited
	_refresh_hero_list(selected_mission)
