# res://scripts/main.gd
# Rapid Response system integrated
extends Control

# UI Node References - will be created dynamically
var money_label: Label
var fame_label: Label
var title_label: Label
var content_container: Control

# Game Manager
var game_manager: Node

# Save Manager
var save_manager: Node

# Rapid Response System
var rapid_manager: RapidResponseManager
var rapid_ui: Control

# Upgrade and recruitment panels
var upgrade_panel: CanvasLayer
var recruitment_panel: CanvasLayer

func _ready() -> void:
	_create_ui()
	_initialize_game_manager()
	_initialize_save_manager()
	await _initialize_rapid_response()
	_setup_upgrade_panel()  # No await needed now
	_setup_recruitment_panel()  # No await needed now
	
	# Wait for UI to be laid out
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Try to load save
	#if not save_manager.load_game():
	#	_initial_ui_update()
	#else:
	#	_refresh_ui()

func _create_ui() -> void:
	"""Create the UI dynamically"""
	set_anchors_preset(PRESET_FULL_RECT)
	
	# Background
	var bg := ColorRect.new()
	bg.color = Color("#0f1624")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# Main container
	var margin := MarginContainer.new()
	margin.name = "MainMargin"
	margin.set_anchors_preset(PRESET_FULL_RECT)
	add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.name = "MainLayout"
	margin.add_child(vbox)
	
	# Header
	var header := PanelContainer.new()
	header.name = "HeaderPanel"
	header.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(header)
	
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("#16213e")
	header_style.set_corner_radius_all(10)
	header.add_theme_stylebox_override("panel", header_style)
	
	var header_hbox := HBoxContainer.new()
	header.add_child(header_hbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "⚡ RAPID RESPONSE"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("#00d9ff"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_hbox.add_child(title_label)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)
	
	# Resources
	var resource_vbox := VBoxContainer.new()
	header_hbox.add_child(resource_vbox)
	
	money_label = Label.new()
	money_label.text = "💰 Money: $500"
	money_label.add_theme_font_size_override("font_size", 18)
	money_label.add_theme_color_override("font_color", Color("#4ecca3"))
	resource_vbox.add_child(money_label)
	
	fame_label = Label.new()
	fame_label.text = "⭐ Fame: 0"
	fame_label.add_theme_font_size_override("font_size", 18)
	fame_label.add_theme_color_override("font_color", Color("#ffd700"))
	resource_vbox.add_child(fame_label)
	
	# Content container
	content_container = Control.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_container)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_manager:
			save_manager.save_game()
		get_tree().quit()

func _initialize_game_manager() -> void:
	game_manager = Node.new()
	game_manager.name = "GameManager"
	game_manager.set_script(preload("res://scripts/game_manager_rapid.gd"))
	add_child(game_manager)
	
	# Connect references
	game_manager.money_label = money_label
	game_manager.fame_label = fame_label
	
	# Connect signals
	game_manager.hero_updated.connect(_on_hero_updated)

func _initialize_save_manager() -> void:
	save_manager = Node.new()
	save_manager.name = "SaveManager"
	save_manager.set_script(preload("res://scripts/save_manager_rapid.gd"))
	add_child(save_manager)
	
	save_manager.set_game_manager(game_manager)

func _initialize_rapid_response() -> void:
	# Create rapid response manager
	rapid_manager = RapidResponseManager.new(game_manager)
	rapid_manager.name = "RapidResponseManager"
	add_child(rapid_manager)
	
	# Store reference in game manager
	game_manager.rapid_manager = rapid_manager
	
	# Wait a frame for manager to be ready
	await get_tree().process_frame
	
	# Create UI
	rapid_ui = Control.new()
	rapid_ui.name = "RapidResponseUI"
	rapid_ui.set_script(preload("res://scripts/rapid_response_ui.gd"))
	content_container.add_child(rapid_ui)
	
	# Wait for UI to be in tree
	await get_tree().process_frame
	
	# Setup UI
	rapid_ui.setup(rapid_manager, game_manager)

func _setup_upgrade_panel() -> void:
	# Use call_deferred to avoid blocking
	call_deferred("_load_upgrade_panel")

func _load_upgrade_panel() -> void:
	var upgrade_scene = load("res://scenes/ui/upgrade_panel.tscn")
	if upgrade_scene:
		upgrade_panel = upgrade_scene.instantiate()
		add_child(upgrade_panel)
	else:
		print("Warning: upgrade_panel.tscn not found")

func _setup_recruitment_panel() -> void:
	# Use call_deferred to avoid blocking
	call_deferred("_load_recruitment_panel")

func _load_recruitment_panel() -> void:
	recruitment_panel = CanvasLayer.new()
	recruitment_panel.name = "RecruitmentPanel"
	recruitment_panel.set_script(preload("res://scripts/recruitment_panel.gd"))
	add_child(recruitment_panel)
	
	# Setup after added to tree
	if recruitment_panel.has_method("setup"):
		recruitment_panel.setup(game_manager, game_manager.recruitment_system)

func _initial_ui_update() -> void:
	money_label.text = "💰 Money: $%d" % game_manager.money
	fame_label.text = "⭐ Fame: %d" % game_manager.fame

func _refresh_ui() -> void:
	money_label.text = "💰 Money: $%d" % game_manager.money
	fame_label.text = "⭐ Fame: %d" % game_manager.fame

func _on_hero_updated(_hero: Hero) -> void:
	# Heroes updated, refresh UI if needed
	pass

func _input(event: InputEvent) -> void:
	# Debug hotkeys
	if event.is_action_pressed("ui_cancel"):
		if Input.is_key_pressed(KEY_F9):
			_debug_reset_heroes()
		elif Input.is_key_pressed(KEY_F8):
			_debug_delete_save()
		elif Input.is_key_pressed(KEY_F7):
			_show_upgrade_panel()
		elif Input.is_key_pressed(KEY_F6):
			_show_recruitment_panel()

func _debug_reset_heroes() -> void:
	print("🔧 RESETTING ALL HEROES")
	for hero in game_manager.heroes:
		hero.is_on_mission = false
		hero.is_recovering = false
		hero.recovery_time_remaining = 0.0
		hero.current_mission_id = ""
		hero.current_health = hero.max_health
		hero.current_stamina = hero.max_stamina
	
	if rapid_manager:
		for hero_id in rapid_manager.hero_energy.keys():
			rapid_manager.hero_energy[hero_id] = 100.0
	
	print("  ✅ All heroes reset!")

func _debug_delete_save() -> void:
	print("🗑️ DELETING SAVE FILE")
	const SAVE_PATH = "user://hero_dispatch_save_rapid.json"
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("  ✅ Save deleted")
	
	# Reload
	get_tree().reload_current_scene()

func _show_upgrade_panel() -> void:
	if upgrade_panel:
		upgrade_panel.show_panel(game_manager)

func _show_recruitment_panel() -> void:
	if recruitment_panel:
		recruitment_panel.show_panel()
