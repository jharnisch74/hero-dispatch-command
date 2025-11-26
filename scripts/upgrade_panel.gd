# res://scripts/upgrade_panel.gd
extends CanvasLayer

# UI References
@onready var overlay: ColorRect = $Overlay
@onready var close_button: Button = $Overlay/CenterContainer/UpgradeWindow/MarginContainer/VBoxContainer/Header/CloseButton
@onready var upgrade_list: VBoxContainer = $Overlay/CenterContainer/UpgradeWindow/MarginContainer/VBoxContainer/ScrollContainer/UpgradeList
@onready var cost_label: Label = $Overlay/CenterContainer/UpgradeWindow/MarginContainer/VBoxContainer/CostLabel

# Data
var game_manager: Node
# Dictionary to store the expanded state: {hero_name: is_expanded (bool)}
var hero_expansion_states: Dictionary = {} 

# Constants for better readability
const HEADER_COLOR = Color("#16213e")
const FONT_COLOR = Color("#00d9ff")
const UPGRADE_COLOR = Color("#4ecca3")
const UPGRADE_HOVER_COLOR = Color("#45b393")

## Initialization and Panel Control
#-------------------------------------------------------------------------------

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	overlay.gui_input.connect(_on_overlay_input)

func show_panel(gm: Node) -> void:
	game_manager = gm
	visible = true
	_populate_upgrades()

func hide_panel() -> void:
	visible = false

func _on_close_pressed() -> void:
	hide_panel()

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click is outside the upgrade window
		var window = $Overlay/CenterContainer/UpgradeWindow
		var window_rect = Rect2(window.global_position, window.size)
		if not window_rect.has_point(event.position):
			hide_panel()

## Upgrade Population and State Management
#-------------------------------------------------------------------------------

func _populate_upgrades() -> void:
	# 1. Capture the current expanded state before clearing the UI
	var current_states: Dictionary = {}
	for child in upgrade_list.get_children():
		# Check for the collapsible hero header button
		if child is Button and child.has_meta("hero_name"):
			var hero_name = child.get_meta("hero_name")
			# The next child is the upgrade_content VBoxContainer
			var next_child_index = child.get_index() + 1
			if next_child_index < upgrade_list.get_child_count():
				var upgrade_content = upgrade_list.get_child(next_child_index)
				# Only capture state if it's the VBoxContainer content
				if upgrade_content is VBoxContainer:
					current_states[hero_name] = upgrade_content.visible
	
	# Clear existing items
	for child in upgrade_list.get_children():
		child.queue_free()
	
	if not game_manager:
		return
	
	# 2. Store captured state for use when recreating the sections
	hero_expansion_states = current_states
	
	# Create a collapsible section for each hero
	for hero in game_manager.heroes:
		_create_hero_collapsible_section(hero)

func _create_hero_collapsible_section(hero: Hero) -> void:
	# 1. Collapsible Header Button
	var toggle_button = Button.new()
	toggle_button.text = "%s %s (Lv.%d)" % [hero.hero_emoji, hero.hero_name, hero.level]
	# Store the hero name to identify the section when reading state
	toggle_button.set_meta("hero_name", hero.hero_name) 
	toggle_button.add_theme_font_size_override("font_size", 18)
	toggle_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Styling for the header button
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = HEADER_COLOR
	btn_style.set_corner_radius_all(5)
	btn_style.content_margin_left = 10
	btn_style.content_margin_right = 10
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	toggle_button.add_theme_stylebox_override("normal", btn_style)
	toggle_button.add_theme_stylebox_override("hover", btn_style)
	toggle_button.add_theme_color_override("font_color", FONT_COLOR)

	upgrade_list.add_child(toggle_button)

	# 2. Container for the Upgrade List (The content that gets toggled)
	var upgrade_content = VBoxContainer.new()
	
	# 3. Restore the expansion state based on the captured dictionary
	var should_be_expanded = hero_expansion_states.get(hero.hero_name, false) # Default to false (collapsed)
	upgrade_content.visible = should_be_expanded
	upgrade_content.add_theme_constant_override("separation", 5) 
	
	# 4. Populate the content container with stat upgrade items
	var stats = [
		{"type": "strength", "label": "💪 Strength", "current": hero.get_total_strength()},
		{"type": "speed", "label": "⚡ Speed", "current": hero.get_total_speed()},
		{"type": "intelligence", "label": "🧠 Intelligence", "current": hero.get_total_intelligence()},
		{"type": "max_health", "label": "❤️ Max Health", "current": int(hero.max_health)},
		{"type": "max_stamina", "label": "⚡ Max Stamina", "current": int(hero.max_stamina)}
	]
	
	for stat in stats:
		# Calling the function to create a single upgrade item 
		var item = _create_upgrade_item(hero, stat.type, stat.label, stat.current) 
		var margin_container = MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", 15) # Indent the stats
		margin_container.add_child(item)
		upgrade_content.add_child(margin_container)
	
	upgrade_list.add_child(upgrade_content)
	
	# 5. Connect the toggle button (This function is connected once per hero)
	toggle_button.pressed.connect(func(): upgrade_content.visible = !upgrade_content.visible)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	upgrade_list.add_child(spacer)

## Helper Function (MUST be at the root level of the script)
#-------------------------------------------------------------------------------

func _create_upgrade_item(hero: Hero, stat_type: String, label_text: String, current_value: int) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.alignment = HBoxContainer.ALIGNMENT_CENTER
	
	# Stat label
	var stat_label = Label.new()
	# The ** around the value makes it stand out slightly (if using a rich text enabled font)
	stat_label.text = "%s: %d" % [label_text, current_value] 
	stat_label.add_theme_font_size_override("font_size", 16)
	stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(stat_label)
	
	# Cost label
	var cost = hero.get_upgrade_cost(stat_type)
	var cost_lbl = Label.new()
	cost_lbl.text = "$%d" % cost
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.add_theme_color_override("font_color", UPGRADE_COLOR)
	container.add_child(cost_lbl)
	
	# Upgrade button
	var upgrade_btn = Button.new()
	upgrade_btn.text = "UPGRADE"
	upgrade_btn.custom_minimum_size = Vector2(100, 0)
	
	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = UPGRADE_COLOR
	btn_style_normal.set_corner_radius_all(5)
	upgrade_btn.add_theme_stylebox_override("normal", btn_style_normal)
	
	var btn_style_hover = StyleBoxFlat.new()
	btn_style_hover.bg_color = UPGRADE_HOVER_COLOR
	btn_style_hover.set_corner_radius_all(5)
	upgrade_btn.add_theme_stylebox_override("hover", btn_style_hover)
	
	# Connects to the handler function below
	upgrade_btn.pressed.connect(func(): _on_upgrade_pressed(hero, stat_type))
	container.add_child(upgrade_btn)
	
	return container

## Upgrade Logic
#-------------------------------------------------------------------------------

func _on_upgrade_pressed(hero: Hero, stat_type: String) -> void:
	if game_manager:
		if game_manager.upgrade_hero_stat(hero, stat_type):
			# This call to _populate_upgrades() refreshes the UI
			# but now correctly restores the expansion state.
			_populate_upgrades() 

func _create_upgrade_items() -> void:
	# Placeholder from original code, kept for compatibility if other code calls it
	pass
