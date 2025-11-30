# res://scripts/rapid_response_ui.gd
# Mobile-friendly swipe-based mission UI
extends Control

var rapid_manager: RapidResponseManager
var game_manager: Node

# UI Nodes
var mission_card: PanelContainer
var mission_emoji: Label
var mission_name: Label
var mission_zone: Label
var mission_difficulty: Label
var mission_rewards: Label
var mission_duration: Label
var best_hero_display: VBoxContainer

var accept_button: Button
var decline_button: Button

var active_missions_panel: VBoxContainer
var streak_label: Label
var stats_panel: HBoxContainer

# Zone selector buttons
var zone_selector_container: HBoxContainer
var zone_buttons: Dictionary = {}
var current_zone_filter: String = "all"  # "all" or specific zone name

# Hero selection overlay
var hero_selection_overlay: ColorRect
var hero_selection_panel: PanelContainer
var hero_buttons_container: VBoxContainer
var selected_hero: Hero = null

# Swipe detection
var swipe_start_pos: Vector2
var is_swiping: bool = false
const SWIPE_THRESHOLD = 100.0

# Card animation
var card_tween: Tween
var card_original_pos: Vector2

func _ready() -> void:
	_create_ui()
	_create_hero_selection_overlay()

func setup(rm: RapidResponseManager, gm: Node) -> void:
	rapid_manager = rm
	game_manager = gm
	
	# Connect signals
	rapid_manager.mission_accepted.connect(_on_mission_accepted)
	rapid_manager.mission_declined.connect(_on_mission_declined)
	rapid_manager.streak_increased.connect(_on_streak_increased)
	rapid_manager.streak_broken.connect(_on_streak_broken)
	
	_update_mission_card()

func _create_ui() -> void:
	# Main container
	set_anchors_preset(PRESET_FULL_RECT)
	
	var bg := ColorRect.new()
	bg.color = Color("#0f1624")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_preset(PRESET_FULL_RECT)
	add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Top stats bar
	_create_top_bar(vbox)
	
	# Main mission card (center, large)
	_create_mission_card(vbox)
	
	# Accept/Decline buttons
	_create_action_buttons(vbox)
	
	# Active missions (bottom)
	_create_active_missions(vbox)

func _create_top_bar(parent: VBoxContainer) -> void:
	stats_panel = HBoxContainer.new()
	stats_panel.add_theme_constant_override("separation", 20)
	parent.add_child(stats_panel)
	
	# Streak
	streak_label = Label.new()
	streak_label.text = "🔥 Streak: 0"
	streak_label.add_theme_font_size_override("font_size", 24)
	streak_label.add_theme_color_override("font_color", Color("#ff8c42"))
	stats_panel.add_child(streak_label)
	
	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_panel.add_child(spacer)
	
	# Available heroes
	var heroes_label := Label.new()
	heroes_label.name = "HeroesLabel"
	heroes_label.text = "👥 3/3"
	heroes_label.add_theme_font_size_override("font_size", 20)
	heroes_label.add_theme_color_override("font_color", Color("#4ecca3"))
	stats_panel.add_child(heroes_label)
	
	# Zone Selector
	_create_zone_selector(parent)

func _create_zone_selector(parent: VBoxContainer) -> void:
	"""Create zone filter buttons"""
	var zone_panel := PanelContainer.new()
	var zone_style := StyleBoxFlat.new()
	zone_style.bg_color = Color("#0f1624")
	zone_style.set_corner_radius_all(10)
	zone_panel.add_theme_stylebox_override("panel", zone_style)
	parent.add_child(zone_panel)
	
	var zone_margin := MarginContainer.new()
	zone_margin.add_theme_constant_override("margin_left", 15)
	zone_margin.add_theme_constant_override("margin_right", 15)
	zone_margin.add_theme_constant_override("margin_top", 10)
	zone_margin.add_theme_constant_override("margin_bottom", 10)
	zone_panel.add_child(zone_margin)
	
	var zone_vbox := VBoxContainer.new()
	zone_vbox.add_theme_constant_override("separation", 8)
	zone_margin.add_child(zone_vbox)
	
	var zone_title := Label.new()
	zone_title.text = "🗺️ ZONE FILTER"
	zone_title.add_theme_font_size_override("font_size", 16)
	zone_title.add_theme_color_override("font_color", Color("#00d9ff"))
	zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_vbox.add_child(zone_title)
	
	zone_selector_container = HBoxContainer.new()
	zone_selector_container.add_theme_constant_override("separation", 8)
	zone_selector_container.alignment = BoxContainer.ALIGNMENT_CENTER
	zone_vbox.add_child(zone_selector_container)
	
	# Create zone buttons
	var zones = [
		{"id": "all", "emoji": "🌐", "name": "All", "color": Color("#4ecca3")},
		{"id": "downtown", "emoji": "🏙️", "name": "Downtown", "color": Color("#ff6b6b")},
		{"id": "industrial", "emoji": "🏭", "name": "Industrial", "color": Color("#ffd93d")},
		{"id": "residential", "emoji": "🏘️", "name": "Residential", "color": Color("#4ecca3")},
		{"id": "park", "emoji": "🌳", "name": "Park", "color": Color("#52b788")},
		{"id": "waterfront", "emoji": "🌊", "name": "Waterfront", "color": Color("#00d9ff")}
	]
	
	for zone_data in zones:
		var btn = _create_zone_button(zone_data)
		zone_selector_container.add_child(btn)
		zone_buttons[zone_data.id] = btn
	
	# Add chaos indicator below zone selector
	var chaos_container := HBoxContainer.new()
	chaos_container.add_theme_constant_override("separation", 15)
	chaos_container.alignment = BoxContainer.ALIGNMENT_CENTER
	zone_vbox.add_child(chaos_container)
	
	# Create mini chaos displays for each zone
	for zone_id in ["downtown", "industrial", "residential", "park", "waterfront"]:
		var mini_chaos = _create_mini_chaos_display(zone_id)
		chaos_container.add_child(mini_chaos)

func _create_zone_button(zone_data: Dictionary) -> Button:
	"""Create a zone filter button"""
	var btn := Button.new()
	btn.text = zone_data.emoji
	btn.custom_minimum_size = Vector2(60, 60)
	btn.add_theme_font_size_override("font_size", 28)
	btn.tooltip_text = zone_data.name
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16213e")
	style.set_corner_radius_all(10)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = zone_data.color
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color("#1a2540")
	hover_style.set_corner_radius_all(10)
	hover_style.border_width_left = 3
	hover_style.border_width_top = 3
	hover_style.border_width_right = 3
	hover_style.border_width_bottom = 3
	hover_style.border_color = zone_data.color
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = zone_data.color.darkened(0.3)
	pressed_style.set_corner_radius_all(10)
	pressed_style.border_width_left = 3
	pressed_style.border_width_top = 3
	pressed_style.border_width_right = 3
	pressed_style.border_width_bottom = 3
	pressed_style.border_color = zone_data.color.lightened(0.3)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.pressed.connect(func(): _on_zone_selected(zone_data.id))
	
	return btn

func _create_mini_chaos_display(zone_id: String) -> VBoxContainer:
	"""Create mini chaos indicator for a zone"""
	var vbox := VBoxContainer.new()
	vbox.name = "ChaosDisplay_" + zone_id
	vbox.add_theme_constant_override("separation", 2)
	vbox.custom_minimum_size = Vector2(50, 0)
	
	var emoji := Label.new()
	emoji.text = _get_zone_emoji(zone_id)
	emoji.add_theme_font_size_override("font_size", 20)
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(emoji)
	
	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(0, 8)
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#1a1a2e")
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#4ecca3")
	bar.add_theme_stylebox_override("fill", fill_style)
	
	vbox.add_child(bar)
	
	var percent := Label.new()
	percent.name = "Percent"
	percent.text = "0%"
	percent.add_theme_font_size_override("font_size", 10)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(percent)
	
	return vbox

func _on_zone_selected(zone_id: String) -> void:
	"""Filter missions by zone"""
	print("Zone selected: %s" % zone_id)
	current_zone_filter = zone_id
	
	# Update button visuals
	for id in zone_buttons.keys():
		var btn = zone_buttons[id]
		if id == zone_id:
			btn.modulate = Color(1.2, 1.2, 1.2)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)
	
	# Filter missions in rapid manager
	if rapid_manager:
		rapid_manager.set_zone_filter(zone_id)
		_update_mission_card()

func _create_mission_card(parent: VBoxContainer) -> void:
	# Card container
	var card_container := CenterContainer.new()
	card_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(card_container)
	
	mission_card = PanelContainer.new()
	mission_card.custom_minimum_size = Vector2(350, 500)
	card_container.add_child(mission_card)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16213e")
	style.set_corner_radius_all(25)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color("#00d9ff")
	mission_card.add_theme_stylebox_override("panel", style)
	
	# Enable input for swipe
	mission_card.mouse_filter = Control.MOUSE_FILTER_STOP
	mission_card.gui_input.connect(_on_card_input)
	
	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 30)
	card_margin.add_theme_constant_override("margin_right", 30)
	card_margin.add_theme_constant_override("margin_top", 30)
	card_margin.add_theme_constant_override("margin_bottom", 30)
	mission_card.add_child(card_margin)
	
	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 15)
	card_margin.add_child(card_vbox)
	
	# Mission emoji (huge!)
	mission_emoji = Label.new()
	mission_emoji.text = "🚨"
	mission_emoji.add_theme_font_size_override("font_size", 120)
	mission_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(mission_emoji)
	
	# Mission name
	mission_name = Label.new()
	mission_name.text = "Bank Robbery"
	mission_name.add_theme_font_size_override("font_size", 28)
	mission_name.add_theme_color_override("font_color", Color("#00d9ff"))
	mission_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_vbox.add_child(mission_name)
	
	# Zone + Difficulty
	var zone_diff := HBoxContainer.new()
	zone_diff.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_child(zone_diff)
	
	mission_zone = Label.new()
	mission_zone.text = "🏙️ Downtown"
	mission_zone.add_theme_font_size_override("font_size", 18)
	zone_diff.add_child(mission_zone)
	
	var sep := Label.new()
	sep.text = " | "
	sep.add_theme_font_size_override("font_size", 18)
	zone_diff.add_child(sep)
	
	mission_difficulty = Label.new()
	mission_difficulty.text = "⭐⭐ Medium"
	mission_difficulty.add_theme_font_size_override("font_size", 18)
	zone_diff.add_child(mission_difficulty)
	
	card_vbox.add_child(HSeparator.new())
	
	# Duration
	mission_duration = Label.new()
	mission_duration.text = "⏱️ 30 seconds"
	mission_duration.add_theme_font_size_override("font_size", 20)
	mission_duration.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(mission_duration)
	
	# Rewards
	mission_rewards = Label.new()
	mission_rewards.text = "💰 $150  |  ⭐ 10 Fame"
	mission_rewards.add_theme_font_size_override("font_size", 22)
	mission_rewards.add_theme_color_override("font_color", Color("#4ecca3"))
	mission_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(mission_rewards)
	
	card_vbox.add_child(HSeparator.new())
	
	# Update best hero display to show it's YOUR choice
	best_hero_display = VBoxContainer.new()
	best_hero_display.add_theme_constant_override("separation", 5)
	card_vbox.add_child(best_hero_display)
	
	var hero_label := Label.new()
	hero_label.text = "🎯 Recommended Hero:"
	hero_label.add_theme_font_size_override("font_size", 14)
	hero_label.add_theme_color_override("font_color", Color("#a8a8a8"))
	hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_hero_display.add_child(hero_label)
	
	var hero_name_label := Label.new()
	hero_name_label.name = "HeroName"
	hero_name_label.text = "🦸 Captain Justice"
	hero_name_label.add_theme_font_size_override("font_size", 18)
	hero_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_hero_display.add_child(hero_name_label)
	
	var choose_label := Label.new()
	choose_label.text = "(Tap to choose different hero)"
	choose_label.add_theme_font_size_override("font_size", 12)
	choose_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	choose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_hero_display.add_child(choose_label)
	
	# Swipe hint
	var hint := Label.new()
	hint.text = "⬅️ Swipe Left = Decline  |  Swipe Right = Select Hero ➡️"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_vbox.add_child(hint)

func _create_action_buttons(parent: VBoxContainer) -> void:
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 30)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(button_row)
	
	# Decline button (red X)
	decline_button = Button.new()
	decline_button.text = "❌\nDECLINE"
	decline_button.custom_minimum_size = Vector2(120, 120)
	decline_button.add_theme_font_size_override("font_size", 20)
	
	var decline_style := StyleBoxFlat.new()
	decline_style.bg_color = Color("#ff3838")
	decline_style.set_corner_radius_all(60)
	decline_button.add_theme_stylebox_override("normal", decline_style)
	
	var decline_hover := StyleBoxFlat.new()
	decline_hover.bg_color = Color("#cc2020")
	decline_hover.set_corner_radius_all(60)
	decline_button.add_theme_stylebox_override("hover", decline_hover)
	
	decline_button.pressed.connect(_on_decline_pressed)
	button_row.add_child(decline_button)
	
	# Accept button (green check) - Now opens hero selection
	accept_button = Button.new()
	accept_button.text = "✅\nSELECT\nHERO"
	accept_button.custom_minimum_size = Vector2(120, 120)
	accept_button.add_theme_font_size_override("font_size", 18)
	
	var accept_style := StyleBoxFlat.new()
	accept_style.bg_color = Color("#4ecca3")
	accept_style.set_corner_radius_all(60)
	accept_button.add_theme_stylebox_override("normal", accept_style)
	
	var accept_hover := StyleBoxFlat.new()
	accept_hover.bg_color = Color("#45b393")
	accept_hover.set_corner_radius_all(60)
	accept_button.add_theme_stylebox_override("hover", accept_hover)
	
	accept_button.pressed.connect(_on_select_hero_pressed)
	button_row.add_child(accept_button)

func _create_active_missions(parent: VBoxContainer) -> void:
	var active_header := Label.new()
	active_header.text = "🚀 ACTIVE MISSIONS"
	active_header.add_theme_font_size_override("font_size", 18)
	active_header.add_theme_color_override("font_color", Color("#00d9ff"))
	parent.add_child(active_header)
	
	active_missions_panel = VBoxContainer.new()
	active_missions_panel.add_theme_constant_override("separation", 5)
	parent.add_child(active_missions_panel)

func _update_mission_card() -> void:
	if not rapid_manager:
		return
	
	var mission = rapid_manager.get_current_mission()
	
	if not mission:
		mission_name.text = "No missions available"
		return
	
	mission_emoji.text = mission.mission_emoji
	mission_name.text = mission.mission_name
	mission_zone.text = _get_zone_emoji(mission.zone) + " " + mission.zone.capitalize()
	mission_difficulty.text = mission.get_difficulty_string()
	mission_difficulty.add_theme_color_override("font_color", mission.get_difficulty_color())
	mission_duration.text = "⏱️ %.0f seconds" % mission.base_duration
	mission_rewards.text = "💰 $%d  |  ⭐ %d Fame" % [mission.money_reward, mission.fame_reward]
	
	# Find best hero
	var best_hero = rapid_manager._find_best_hero_for_mission(mission)
	if best_hero:
		var hero_name_label = best_hero_display.get_node("HeroName")
		hero_name_label.text = best_hero.hero_emoji + " " + best_hero.hero_name
		best_hero_display.visible = true
	else:
		best_hero_display.visible = false
	
	# Update available heroes count
	var heroes_label = stats_panel.get_node("HeroesLabel")
	var available = rapid_manager.get_available_heroes_count()
	heroes_label.text = "👥 %d/%d" % [available, game_manager.heroes.size()]
	
	# Enable/disable buttons
	accept_button.disabled = best_hero == null
	decline_button.disabled = false

func _update_active_missions() -> void:
	# Clear existing
	for child in active_missions_panel.get_children():
		child.queue_free()
	
	if not rapid_manager:
		return
	
	for slot in rapid_manager.active_slots:
		var mission: Mission = slot.mission
		var hero: Hero = slot.hero
		var time_left: float = slot.time_remaining
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		active_missions_panel.add_child(row)
		
		var mission_label := Label.new()
		mission_label.text = "%s %s" % [mission.mission_emoji, mission.mission_name]
		mission_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(mission_label)
		
		var timer := Label.new()
		timer.text = "⏱️ %.0fs" % time_left
		timer.add_theme_color_override("font_color", Color("#ff8c42"))
		row.add_child(timer)

func _on_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			swipe_start_pos = event.position
			is_swiping = true
		elif not event.pressed and is_swiping:
			var swipe_distance = event.position - swipe_start_pos
			is_swiping = false
			
			if swipe_distance.x > SWIPE_THRESHOLD:
				# Swipe right = open hero selection
				_show_hero_selection()
			elif swipe_distance.x < -SWIPE_THRESHOLD:
				# Swipe left = decline
				_animate_decline()

func _animate_accept() -> void:
	"""Animate card sliding right and open hero selection"""
	if accept_button.disabled:
		return
	
	if card_tween:
		card_tween.kill()
	
	card_tween = create_tween()
	card_tween.set_ease(Tween.EASE_OUT)
	card_tween.set_trans(Tween.TRANS_BACK)
	
	# Slide right slightly
	card_tween.parallel().tween_property(mission_card, "position:x", mission_card.position.x + 100, 0.2)
	
	card_tween.tween_callback(_show_hero_selection)
	card_tween.tween_callback(func(): 
		mission_card.position.x = card_original_pos.x
	)

func _animate_decline() -> void:
	if card_tween:
		card_tween.kill()
	
	card_tween = create_tween()
	card_tween.set_ease(Tween.EASE_OUT)
	card_tween.set_trans(Tween.TRANS_BACK)
	
	# Slide left and fade
	card_tween.parallel().tween_property(mission_card, "position:x", mission_card.position.x - 500, 0.3)
	card_tween.parallel().tween_property(mission_card, "modulate:a", 0.0, 0.3)
	
	card_tween.tween_callback(_on_decline_pressed)
	card_tween.tween_callback(func(): 
		mission_card.position.x = card_original_pos.x
		mission_card.modulate.a = 1.0
	)

func _on_accept_pressed() -> void:
	if rapid_manager and rapid_manager.accept_mission():
		_update_mission_card()
		_update_active_missions()

func _on_decline_pressed() -> void:
	if rapid_manager:
		rapid_manager.decline_mission()
		_update_mission_card()

func _on_mission_accepted(_mission: Mission) -> void:
	# Play success sound/animation
	pass

func _on_mission_declined(_mission: Mission) -> void:
	# Play decline sound/animation
	pass

func _on_streak_increased(new_streak: int) -> void:
	streak_label.text = "🔥 Streak: %d" % new_streak
	
	# Animate streak
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	streak_label.scale = Vector2(0.5, 0.5)
	tween.tween_property(streak_label, "scale", Vector2(1.0, 1.0), 0.5)

func _on_streak_broken() -> void:
	streak_label.text = "🔥 Streak: 0"
	streak_label.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(streak_label, "modulate", Color.WHITE, 0.5)

func _get_zone_emoji(zone: String) -> String:
	match zone:
		"downtown": return "🏙️"
		"industrial": return "🏭"
		"residential": return "🏘️"
		"park": return "🌳"
		"waterfront": return "🌊"
		_: return "📍"

func _update_chaos_displays() -> void:
	"""Update mini chaos indicators"""
	if not game_manager or not game_manager.chaos_system:
		return
	
	for zone_id in ["downtown", "industrial", "residential", "park", "waterfront"]:
		var display = zone_selector_container.get_parent().get_node_or_null("../HBoxContainer/ChaosDisplay_" + zone_id)
		if not display:
			continue
		
		var chaos_level = game_manager.chaos_system.get_chaos_level(zone_id)
		var chaos_color = game_manager.chaos_system.get_chaos_color(zone_id)
		
		var bar = display.get_node_or_null("Bar")
		var percent_label = display.get_node_or_null("Percent")
		
		if bar:
			bar.value = chaos_level
			var fill_style = bar.get_theme_stylebox("fill")
			if fill_style is StyleBoxFlat:
				fill_style.bg_color = chaos_color
		
		if percent_label:
			percent_label.text = "%.0f%%" % chaos_level
			percent_label.add_theme_color_override("font_color", chaos_color)

func _process(_delta: float) -> void:
	_update_active_missions()
	_update_chaos_displays()

func _create_hero_selection_overlay() -> void:
	"""Create popup overlay for hero selection"""
	hero_selection_overlay = ColorRect.new()
	hero_selection_overlay.color = Color(0, 0, 0, 0.85)
	hero_selection_overlay.set_anchors_preset(PRESET_FULL_RECT)
	hero_selection_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hero_selection_overlay.visible = false
	add_child(hero_selection_overlay)
	
	# Click overlay to cancel
	hero_selection_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_hero_selection()
	)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	hero_selection_overlay.add_child(center)
	
	hero_selection_panel = PanelContainer.new()
	hero_selection_panel.custom_minimum_size = Vector2(400, 600)
	center.add_child(hero_selection_panel)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16213e")
	style.set_corner_radius_all(20)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color("#00d9ff")
	hero_selection_panel.add_theme_stylebox_override("panel", style)
	
	# Prevent clicks from passing through to overlay
	hero_selection_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	hero_selection_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var title := Label.new()
	title.text = "SELECT HERO"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#00d9ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(_close_hero_selection)
	header.add_child(close_btn)
	
	vbox.add_child(HSeparator.new())
	
	# Scroll container for heroes
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 450)
	vbox.add_child(scroll)
	
	hero_buttons_container = VBoxContainer.new()
	hero_buttons_container.add_theme_constant_override("separation", 10)
	scroll.add_child(hero_buttons_container)

func _show_hero_selection() -> void:
	"""Show hero selection popup with available heroes"""
	if not rapid_manager or not game_manager:
		return
	
	var mission = rapid_manager.get_current_mission()
	if not mission:
		return
	
	# Clear existing buttons
	for child in hero_buttons_container.get_children():
		child.queue_free()
	
	# Create button for each available hero
	for hero in game_manager.heroes:
		var can_use = hero.is_available() and rapid_manager.get_hero_energy(hero.hero_id) >= rapid_manager.ENERGY_DRAIN_PER_MISSION
		
		var hero_btn := _create_hero_button(hero, mission, can_use)
		hero_buttons_container.add_child(hero_btn)
	
	# Show overlay with animation
	hero_selection_overlay.visible = true
	hero_selection_overlay.modulate.a = 0.0
	hero_selection_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(hero_selection_overlay, "modulate:a", 1.0, 0.2)
	tween.tween_property(hero_selection_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _create_hero_button(hero: Hero, mission: Mission, can_use: bool) -> PanelContainer:
	"""Create a hero selection button"""
	var panel := PanelContainer.new()
	
	var style := StyleBoxFlat.new()
	if can_use:
		style.bg_color = Color("#0f1624")
		style.border_color = Color("#4ecca3")
	else:
		style.bg_color = Color("#1a1a1a")
		style.border_color = Color("#555555")
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 100)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(1, 1, 1, 0.1)
	btn.add_theme_stylebox_override("hover", btn_hover)
	
	panel.add_child(btn)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)
	
	# Left: Hero info
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 5)
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(left_vbox)
	
	var name_label := Label.new()
	name_label.text = "%s %s (Lv.%d)" % [hero.hero_emoji, hero.hero_name, hero.level]
	name_label.add_theme_font_size_override("font_size", 18)
	if can_use:
		name_label.add_theme_color_override("font_color", Color("#00d9ff"))
	else:
		name_label.add_theme_color_override("font_color", Color("#666666"))
	left_vbox.add_child(name_label)
	
	var stats_label := Label.new()
	stats_label.text = "💪 %d  ⚡ %d  🧠 %d" % [hero.get_total_strength(), hero.get_total_speed(), hero.get_total_intelligence()]
	stats_label.add_theme_font_size_override("font_size", 14)
	left_vbox.add_child(stats_label)
	
	# Specialty match indicator
	var has_match = false
	for spec in mission.preferred_specialties:
		if spec in hero.specialties:
			has_match = true
			break
	
	if has_match:
		var match_label := Label.new()
		match_label.text = "✨ Specialty Match!"
		match_label.add_theme_font_size_override("font_size", 14)
		match_label.add_theme_color_override("font_color", Color("#ffcc00"))
		left_vbox.add_child(match_label)
	
	# Right: Energy bar
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 5)
	right_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(right_vbox)
	
	var energy_label := Label.new()
	energy_label.text = "Energy"
	energy_label.add_theme_font_size_override("font_size", 12)
	energy_label.add_theme_color_override("font_color", Color("#a8a8a8"))
	right_vbox.add_child(energy_label)
	
	var energy_bar := ProgressBar.new()
	energy_bar.custom_minimum_size = Vector2(120, 20)
	energy_bar.max_value = 100
	energy_bar.value = rapid_manager.get_hero_energy(hero.hero_id)
	
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("#1a1a2e")
	energy_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill := StyleBoxFlat.new()
	if can_use:
		bar_fill.bg_color = Color("#4ecca3")
	else:
		bar_fill.bg_color = Color("#555555")
	energy_bar.add_theme_stylebox_override("fill", bar_fill)
	
	right_vbox.add_child(energy_bar)
	
	var energy_text := Label.new()
	energy_text.text = "%.0f%%" % rapid_manager.get_hero_energy(hero.hero_id)
	energy_text.add_theme_font_size_override("font_size", 14)
	right_vbox.add_child(energy_text)
	
	# Status text
	if not can_use:
		var status := Label.new()
		if not hero.is_available():
			status.text = "❌ " + hero.get_status_text()
		else:
			status.text = "😓 Not enough energy"
		status.add_theme_font_size_override("font_size", 12)
		status.add_theme_color_override("font_color", Color("#ff6b6b"))
		left_vbox.add_child(status)
	
	# Connect button
	if can_use:
		btn.pressed.connect(func(): _on_hero_selected(hero))
	else:
		btn.disabled = true
	
	return panel

func _on_hero_selected(hero: Hero) -> void:
	"""Hero was selected from the popup"""
	selected_hero = hero
	_close_hero_selection()
	_on_accept_with_hero(hero)

func _close_hero_selection() -> void:
	"""Close hero selection popup"""
	if not hero_selection_overlay.visible:
		return
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(hero_selection_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_property(hero_selection_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_callback(func(): hero_selection_overlay.visible = false)

func _on_select_hero_pressed() -> void:
	"""Open hero selection popup"""
	_show_hero_selection()

func _on_accept_with_hero(hero: Hero) -> void:
	"""Accept mission with specific hero"""
	if not rapid_manager:
		return
	
	var mission = rapid_manager.get_current_mission()
	if not mission:
		return
	
	# Check if we have an available slot
	if rapid_manager.active_slots.size() >= rapid_manager.MAX_ACTIVE_SLOTS:
		game_manager.update_status("❌ All mission slots full!")
		return
	
	# Remove from queue
	rapid_manager.mission_queue.erase(mission)
	rapid_manager._fill_mission_queue()
	
	# Drain hero energy
	rapid_manager.hero_energy[hero.hero_id] -= rapid_manager.ENERGY_DRAIN_PER_MISSION
	if rapid_manager.hero_energy[hero.hero_id] <= 0:
		rapid_manager.hero_energy[hero.hero_id] = 0
		rapid_manager.hero_energy_depleted.emit(hero)
	
	# Start mission
	mission.assigned_hero_ids.append(hero.hero_id)
	mission.start_mission([hero])
	
	# Add to active slots
	rapid_manager.active_slots.append({
		"mission": mission,
		"hero": hero,
		"time_remaining": mission.base_duration
	})
	
	# Update streak
	rapid_manager.current_streak += 1
	if rapid_manager.current_streak > rapid_manager.best_streak:
		rapid_manager.best_streak = rapid_manager.current_streak
	rapid_manager.streak_increased.emit(rapid_manager.current_streak)
	
	print("✅ MISSION ACCEPTED: %s by %s (Streak: %d)" % [mission.mission_name, hero.hero_name, rapid_manager.current_streak])
	
	rapid_manager.mission_accepted.emit(mission)
	
	_update_mission_card()
	_update_active_missions()
