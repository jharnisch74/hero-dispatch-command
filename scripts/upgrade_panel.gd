# res://scripts/upgrade_panel.gd
extends CanvasLayer

# UI References
@onready var overlay: ColorRect = $Overlay
@onready var close_button: Button = $Overlay/CenterContainer/UpgradeWindow/MarginContainer/VBoxContainer/Header/CloseButton
@onready var upgrade_list: VBoxContainer = $Overlay/CenterContainer/UpgradeWindow/MarginContainer/VBoxContainer/ScrollContainer/UpgradeList
@onready var cost_label: Label = $Overlay/CenterContainer/UpgradeWindow/MarginContainer/VBoxContainer/CostLabel

# Data
var game_manager: Node
var upgrade_item_scene: PackedScene

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	overlay.gui_input.connect(_on_overlay_input)
	
	# Create upgrade item scene programmatically since we don't have a separate scene file
	_create_upgrade_items()

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

func _populate_upgrades() -> void:
	# Clear existing items
	for child in upgrade_list.get_children():
		child.queue_free()
	
	if not game_manager:
		return
	
	# Create upgrade items for each hero
	for hero in game_manager.heroes:
		_create_hero_upgrade_section(hero)

func _create_hero_upgrade_section(hero: Hero) -> void:
	# Hero header
	var header = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("#16213e")
	header_style.set_corner_radius_all(5)
	header.add_theme_stylebox_override("panel", header_style)
	
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 10)
	header_margin.add_theme_constant_override("margin_right", 10)
	header_margin.add_theme_constant_override("margin_top", 10)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(header_margin)
	
	var header_label = Label.new()
	header_label.text = "%s %s (Lv.%d)" % [hero.hero_emoji, hero.hero_name, hero.level]
	header_label.add_theme_font_size_override("font_size", 18)
	header_label.add_theme_color_override("font_color", Color("#00d9ff"))
	header_margin.add_child(header_label)
	
	upgrade_list.add_child(header)
	
	# Upgrade buttons
	var stats = [
		{"type": "strength", "label": "💪 Strength", "current": hero.get_total_strength()},
		{"type": "speed", "label": "⚡ Speed", "current": hero.get_total_speed()},
		{"type": "intelligence", "label": "🧠 Intelligence", "current": hero.get_total_intelligence()},
		{"type": "max_health", "label": "❤️ Max Health", "current": int(hero.max_health)},
		{"type": "max_stamina", "label": "⚡ Max Stamina", "current": int(hero.max_stamina)}
	]
	
	for stat in stats:
		var item = _create_upgrade_item(hero, stat.type, stat.label, stat.current)
		upgrade_list.add_child(item)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	upgrade_list.add_child(spacer)

func _create_upgrade_item(hero: Hero, stat_type: String, label_text: String, current_value: int) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Stat label
	var stat_label = Label.new()
	stat_label.text = "%s: %d" % [label_text, current_value]
	stat_label.add_theme_font_size_override("font_size", 16)
	stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(stat_label)
	
	# Cost label
	var cost = hero.get_upgrade_cost(stat_type)
	var cost_lbl = Label.new()
	cost_lbl.text = "$%d" % cost
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.add_theme_color_override("font_color", Color("#4ecca3"))
	container.add_child(cost_lbl)
	
	# Upgrade button
	var upgrade_btn = Button.new()
	upgrade_btn.text = "UPGRADE"
	upgrade_btn.custom_minimum_size = Vector2(100, 0)
	
	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = Color("#4ecca3")
	btn_style_normal.set_corner_radius_all(5)
	upgrade_btn.add_theme_stylebox_override("normal", btn_style_normal)
	
	var btn_style_hover = StyleBoxFlat.new()
	btn_style_hover.bg_color = Color("#45b393")
	btn_style_hover.set_corner_radius_all(5)
	upgrade_btn.add_theme_stylebox_override("hover", btn_style_hover)
	
	upgrade_btn.pressed.connect(func(): _on_upgrade_pressed(hero, stat_type))
	container.add_child(upgrade_btn)
	
	return container

func _on_upgrade_pressed(hero: Hero, stat_type: String) -> void:
	if game_manager:
		if game_manager.upgrade_hero_stat(hero, stat_type):
			_populate_upgrades()

func _create_upgrade_items() -> void:
	pass  # Items are created dynamically
