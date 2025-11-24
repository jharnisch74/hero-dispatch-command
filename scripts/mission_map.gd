# res://scripts/mission_map.gd
# Updated version with fixes

extends Control

# Map settings
const MAP_WIDTH = 800
const MAP_HEIGHT = 600
const MISSION_ICON_SIZE = 50

# References
var game_manager: Node
var mission_markers: Dictionary = {}  # mission_id -> marker node

# Selected mission
var selected_mission: Mission = null

# Track used positions to prevent overlap
var used_positions: Dictionary = {}  # mission_id -> Vector2

# UI Elements (created programmatically)
var map_canvas: Control
var mission_detail_panel: PanelContainer
var detail_name_label: Label
var detail_difficulty_label: Label
var detail_description_label: Label
var detail_rewards_label: Label
var detail_requirements_label: Label
var detail_assigned_label: Label
var detail_timer_label: Label
var detail_timer_progress: ProgressBar
var detail_start_button: Button
var detail_close_button: Button

# Signals
signal mission_clicked(mission: Mission)
signal mission_started(mission: Mission)

# City zones for mission placement - now using percentages
var city_zones = {
	"downtown": {"x": 0.5, "y": 0.5, "width": 0.25, "height": 0.25},
	"industrial": {"x": 0.15, "y": 0.15, "width": 0.2, "height": 0.2},
	"residential": {"x": 0.75, "y": 0.75, "width": 0.2, "height": 0.2},
	"park": {"x": 0.75, "y": 0.15, "width": 0.15, "height": 0.15},
	"waterfront": {"x": 0.15, "y": 0.75, "width": 0.2, "height": 0.15}
}

func _ready() -> void:
	_create_map_ui()

func setup(gm: Node) -> void:
	game_manager = gm

func _create_map_ui() -> void:
	# Main map canvas - fill entire control
	map_canvas = Control.new()
	map_canvas.name = "MapCanvas"
	map_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_canvas.clip_contents = false
	add_child(map_canvas)
	
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color("#1a1a2e")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	map_canvas.add_child(bg)
	
	# Draw city zones
	call_deferred("_draw_city_background")
	
	# Mission detail panel (hidden by default)
	_create_detail_panel()

func _draw_city_background() -> void:
	# Wait a frame to ensure size is set
	await get_tree().process_frame
	
	# Clear old zone visuals
	for child in map_canvas.get_children():
		if "Zone_" in child.name or "Border_" in child.name or "Label_" in child.name:
			child.queue_free()
	
	# Get actual map size
	var map_width = size.x if size.x > 0 else MAP_WIDTH
	var map_height = size.y if size.y > 0 else MAP_HEIGHT
	
	print("Drawing zones - Map size: ", map_width, "x", map_height)
	
	# Draw stylized city zones as rectangles
	for zone_name in city_zones:
		var zone = city_zones[zone_name]
		
		# Calculate actual pixel positions
		var zone_center_x = zone.x * map_width
		var zone_center_y = zone.y * map_height
		var zone_width = zone.width * map_width
		var zone_height = zone.height * map_height
		
		var zone_x = zone_center_x - zone_width / 2
		var zone_y = zone_center_y - zone_height / 2
		
		# Create zone as ColorRect
		var zone_rect = ColorRect.new()
		zone_rect.name = "Zone_" + zone_name
		zone_rect.position = Vector2(zone_x, zone_y)
		zone_rect.size = Vector2(zone_width, zone_height)
		zone_rect.z_index = 0  # Changed from -50 to 0
		zone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Set color based on zone
		match zone_name:
			"downtown":
				zone_rect.color = Color(1.0, 0.42, 0.42, 0.5)  # Red
			"industrial":
				zone_rect.color = Color(1.0, 0.84, 0.0, 0.5)  # Yellow
			"residential":
				zone_rect.color = Color(0.3, 0.8, 0.64, 0.5)  # Teal
			"park":
				zone_rect.color = Color(0.32, 0.81, 0.4, 0.5)  # Green
			"waterfront":
				zone_rect.color = Color(0.0, 0.85, 1.0, 0.5)  # Cyan
		
		map_canvas.add_child(zone_rect)
		
		# Add border
		var border = ReferenceRect.new()
		border.name = "Border_" + zone_name
		border.position = Vector2(zone_x, zone_y)
		border.size = Vector2(zone_width, zone_height)
		border.border_color = Color(1, 1, 1, 0.6)
		border.border_width = 3.0
		border.z_index = 1
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_canvas.add_child(border)
		
		# Add label
		var label = Label.new()
		label.name = "Label_" + zone_name
		label.text = zone_name.to_upper()
		label.position = Vector2(zone_x + 15, zone_y + 15)
		label.z_index = 2
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 3)
		map_canvas.add_child(label)

func _create_detail_panel() -> void:
	mission_detail_panel = PanelContainer.new()
	mission_detail_panel.name = "MissionDetailPanel"
	mission_detail_panel.visible = false
	mission_detail_panel.custom_minimum_size = Vector2(350, 300)
	mission_detail_panel.z_index = 1000
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#16213e")
	panel_style.set_corner_radius_all(10)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color("#00d9ff")
	mission_detail_panel.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	mission_detail_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Header with close button
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	detail_name_label = Label.new()
	detail_name_label.add_theme_font_size_override("font_size", 20)
	detail_name_label.add_theme_color_override("font_color", Color("#00d9ff"))
	detail_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(detail_name_label)
	
	detail_close_button = Button.new()
	detail_close_button.text = "✕"
	detail_close_button.custom_minimum_size = Vector2(30, 30)
	detail_close_button.pressed.connect(_on_detail_close_pressed)
	header.add_child(detail_close_button)
	
	detail_difficulty_label = Label.new()
	detail_difficulty_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(detail_difficulty_label)
	
	var separator1 = HSeparator.new()
	vbox.add_child(separator1)
	
	detail_description_label = Label.new()
	detail_description_label.add_theme_font_size_override("font_size", 14)
	detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(detail_description_label)
	
	detail_rewards_label = Label.new()
	detail_rewards_label.add_theme_font_size_override("font_size", 14)
	detail_rewards_label.add_theme_color_override("font_color", Color("#4ecca3"))
	vbox.add_child(detail_rewards_label)
	
	detail_requirements_label = Label.new()
	detail_requirements_label.add_theme_font_size_override("font_size", 12)
	detail_requirements_label.add_theme_color_override("font_color", Color("#a8a8a8"))
	detail_requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(detail_requirements_label)
	
	detail_assigned_label = Label.new()
	detail_assigned_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(detail_assigned_label)
	
	# Timer row
	var timer_container = VBoxContainer.new()
	vbox.add_child(timer_container)
	
	detail_timer_label = Label.new()
	detail_timer_label.add_theme_font_size_override("font_size", 14)
	detail_timer_label.visible = false
	timer_container.add_child(detail_timer_label)
	
	detail_timer_progress = ProgressBar.new()
	detail_timer_progress.custom_minimum_size = Vector2(0, 20)
	detail_timer_progress.visible = false
	var progress_bg = StyleBoxFlat.new()
	progress_bg.bg_color = Color("#2d2d44")
	var progress_fill = StyleBoxFlat.new()
	progress_fill.bg_color = Color("#00d9ff")
	detail_timer_progress.add_theme_stylebox_override("background", progress_bg)
	detail_timer_progress.add_theme_stylebox_override("fill", progress_fill)
	timer_container.add_child(detail_timer_progress)
	
	detail_start_button = Button.new()
	detail_start_button.text = "🚀 START MISSION"
	detail_start_button.custom_minimum_size = Vector2(0, 40)
	detail_start_button.pressed.connect(_on_detail_start_pressed)
	vbox.add_child(detail_start_button)
	
	add_child(mission_detail_panel)

func refresh_missions() -> void:
	if not game_manager:
		return
	
	# Redraw zones to ensure they fill the container
	_draw_city_background()
	
	# Track which missions exist now
	var current_mission_ids = {}
	
	for mission in game_manager.active_missions:
		current_mission_ids[mission.mission_id] = mission
	for mission in game_manager.available_missions:
		current_mission_ids[mission.mission_id] = mission
	
	# Remove markers for missions that no longer exist
	var markers_to_remove = []
	for mission_id in mission_markers:
		if not mission_id in current_mission_ids:
			markers_to_remove.append(mission_id)
	
	for mission_id in markers_to_remove:
		mission_markers[mission_id].queue_free()
		mission_markers.erase(mission_id)
		used_positions.erase(mission_id)
	
	# Create/update markers
	for mission in game_manager.active_missions:
		if not mission.mission_id in mission_markers:
			_create_mission_marker(mission, true)
		else:
			_update_marker_style(mission_markers[mission.mission_id], mission, true)
	
	for mission in game_manager.available_missions:
		if not mission.mission_id in mission_markers:
			_create_mission_marker(mission, false)
		else:
			_update_marker_style(mission_markers[mission.mission_id], mission, false)
	
	if selected_mission:
		_update_detail_panel()

func _update_marker_style(marker: PanelContainer, mission: Mission, is_active: bool) -> void:
	var marker_style = StyleBoxFlat.new()
	if is_active:
		marker_style.bg_color = Color("#ff8c42")
		marker_style.border_color = Color("#ff6b6b")
	else:
		marker_style.bg_color = mission.get_difficulty_color()
		marker_style.border_color = Color("#ffffff", 0.8)
	marker_style.set_corner_radius_all(MISSION_ICON_SIZE / 2)
	marker_style.border_width_left = 3
	marker_style.border_width_top = 3
	marker_style.border_width_right = 3
	marker_style.border_width_bottom = 3
	marker.add_theme_stylebox_override("panel", marker_style)

func _create_mission_marker(mission: Mission, is_active: bool) -> void:
	var marker = PanelContainer.new()
	marker.name = "Marker_" + mission.mission_id
	marker.custom_minimum_size = Vector2(MISSION_ICON_SIZE, MISSION_ICON_SIZE)
	
	var pos = _get_mission_position(mission)
	marker.position = pos - Vector2(MISSION_ICON_SIZE / 2, MISSION_ICON_SIZE / 2)
	
	var marker_style = StyleBoxFlat.new()
	if is_active:
		marker_style.bg_color = Color("#ff8c42")
		marker_style.border_color = Color("#ff6b6b")
	else:
		marker_style.bg_color = mission.get_difficulty_color()
		marker_style.border_color = Color("#ffffff", 0.8)
	marker_style.set_corner_radius_all(MISSION_ICON_SIZE / 2)
	marker_style.border_width_left = 3
	marker_style.border_width_top = 3
	marker_style.border_width_right = 3
	marker_style.border_width_bottom = 3
	marker.add_theme_stylebox_override("panel", marker_style)
	
	var icon_label = Label.new()
	icon_label.text = mission.mission_emoji
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 28)
	marker.add_child(icon_label)
	
	if is_active:
		var tween = create_tween().set_loops()
		tween.tween_property(marker, "scale", Vector2(1.1, 1.1), 0.5)
		tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.5)
	
	marker.gui_input.connect(func(event): _on_marker_clicked(event, mission))
	marker.mouse_entered.connect(func(): marker.modulate = Color(1.2, 1.2, 1.2))
	marker.mouse_exited.connect(func(): marker.modulate = Color.WHITE)
	
	map_canvas.add_child(marker)
	marker.z_index = 10  # Above zones
	mission_markers[mission.mission_id] = marker

func _get_mission_position(mission: Mission) -> Vector2:
	# Check if we already have a position
	if mission.mission_id in used_positions:
		return used_positions[mission.mission_id]
	
	var zone_name = "downtown"
	
	if "Rescue" in mission.mission_name or "Fire" in mission.mission_name:
		zone_name = "residential"
	elif "Cyber" in mission.mission_name or "Tech" in mission.mission_name or "Bomb" in mission.mission_name:
		zone_name = "industrial"
	elif "Cat" in mission.mission_name or "Pet" in mission.mission_name:
		zone_name = "park"
	elif "Bank" in mission.mission_name or "Robbery" in mission.mission_name or "Villain" in mission.mission_name or "Gang" in mission.mission_name:
		zone_name = "downtown"
	elif "Bridge" in mission.mission_name or "Hostage" in mission.mission_name:
		zone_name = "waterfront"
	
	var zone = city_zones[zone_name]
	var map_width = size.x if size.x > 0 else MAP_WIDTH
	var map_height = size.y if size.y > 0 else MAP_HEIGHT
	
	var zone_center_x = zone.x * map_width
	var zone_center_y = zone.y * map_height
	var zone_width = zone.width * map_width
	var zone_height = zone.height * map_height
	
	var seed_value = hash(mission.mission_id)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var max_attempts = 20
	var min_distance = MISSION_ICON_SIZE * 1.5
	
	for attempt in range(max_attempts):
		var margin = MISSION_ICON_SIZE
		var x = zone_center_x + (rng.randf() - 0.5) * (zone_width - margin)
		var y = zone_center_y + (rng.randf() - 0.5) * (zone_height - margin)
		var pos = Vector2(x, y)
		
		var overlaps = false
		for other_pos in used_positions.values():
			if pos.distance_to(other_pos) < min_distance:
				overlaps = true
				break
		
		if not overlaps:
			used_positions[mission.mission_id] = pos
			return pos
	
	var fallback_x = zone_center_x + (rng.randf() - 0.5) * (zone_width - MISSION_ICON_SIZE)
	var fallback_y = zone_center_y + (rng.randf() - 0.5) * (zone_height - MISSION_ICON_SIZE)
	var fallback_pos = Vector2(fallback_x, fallback_y)
	used_positions[mission.mission_id] = fallback_pos
	return fallback_pos

func _on_marker_clicked(event: InputEvent, mission: Mission) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_mission = mission
		
		# Smart positioning to keep panel on screen
		if mission.mission_id in mission_markers:
			var marker = mission_markers[mission.mission_id]
			var marker_pos = marker.position
			var marker_center = marker_pos + Vector2(MISSION_ICON_SIZE / 2, MISSION_ICON_SIZE / 2)
			
			var panel_width = 350
			var panel_height = 330
			var offset = 20
			
			# Default: right of mission
			var panel_x = marker_center.x + MISSION_ICON_SIZE / 2 + offset
			var panel_y = marker_center.y - panel_height / 2
			
			# If too close to right edge, show on left
			if panel_x + panel_width > size.x - 10:
				panel_x = marker_center.x - MISSION_ICON_SIZE / 2 - panel_width - offset
			
			# If still off screen left, center it
			if panel_x < 10:
				panel_x = (size.x - panel_width) / 2
			
			# Vertical adjustments
			if panel_y < 10:
				panel_y = 10
			if panel_y + panel_height > size.y - 10:
				panel_y = size.y - panel_height - 10
			
			mission_detail_panel.position = Vector2(panel_x, panel_y)
		
		mission_detail_panel.visible = true
		_update_detail_panel()
		mission_clicked.emit(mission)

func _update_detail_panel() -> void:
	if not selected_mission or not game_manager:
		return
	
	detail_name_label.text = "%s %s" % [selected_mission.mission_emoji, selected_mission.mission_name]
	detail_difficulty_label.text = selected_mission.get_difficulty_string()
	detail_difficulty_label.add_theme_color_override("font_color", selected_mission.get_difficulty_color())
	detail_description_label.text = selected_mission.description
	detail_rewards_label.text = "💰 $%d  |  ⭐ %d Fame" % [selected_mission.money_reward, selected_mission.fame_reward]
	detail_requirements_label.text = selected_mission.get_requirements_text()
	
	if selected_mission.assigned_hero_ids.size() > 0:
		var hero_names = []
		for hero_id in selected_mission.assigned_hero_ids:
			var hero = game_manager.get_hero_by_id(hero_id)
			if hero:
				hero_names.append(hero.hero_name)
		detail_assigned_label.text = "👥 Assigned: %s" % ", ".join(hero_names)
	else:
		detail_assigned_label.text = "👥 No heroes assigned"
	
	if selected_mission.is_active:
		detail_timer_label.visible = true
		detail_timer_progress.visible = true
		detail_start_button.visible = false
		_update_timer_display()
	elif selected_mission.is_completed:
		detail_timer_label.visible = false
		detail_timer_progress.visible = false
		detail_start_button.text = "COMPLETED"
		detail_start_button.disabled = true
	else:
		detail_timer_label.visible = false
		detail_timer_progress.visible = false
		detail_start_button.visible = true
		detail_start_button.disabled = not selected_mission.can_start()
		if selected_mission.can_start():
			detail_start_button.text = "🚀 START MISSION"
		else:
			detail_start_button.text = "ASSIGN HEROES FIRST"

func _update_timer_display() -> void:
	if not selected_mission or not selected_mission.is_active:
		return
	
	var minutes = int(selected_mission.time_remaining) / 60
	var seconds = int(selected_mission.time_remaining) % 60
	detail_timer_label.text = "⏱️ Time: %02d:%02d" % [minutes, seconds]
	
	detail_timer_progress.max_value = selected_mission.base_duration
	detail_timer_progress.value = selected_mission.base_duration - selected_mission.time_remaining

func _process(_delta: float) -> void:
	if mission_detail_panel and mission_detail_panel.visible and selected_mission and selected_mission.is_active:
		_update_timer_display()

func _on_detail_close_pressed() -> void:
	if mission_detail_panel:
		mission_detail_panel.visible = false
	selected_mission = null

func _on_detail_start_pressed() -> void:
	if selected_mission:
		mission_started.emit(selected_mission)
		_update_detail_panel()

func close_detail_panel() -> void:
	if mission_detail_panel:
		mission_detail_panel.visible = false
	selected_mission = null
