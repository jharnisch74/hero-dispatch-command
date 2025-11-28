# res://scripts/mission_map.gd
extends Control

const MISSION_ICON_SIZE: int = 50

var game_manager: Node = null
var mission_markers: Dictionary = {}
var selected_mission: Variant = null
var used_positions: Dictionary = {}

# UI nodes
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

signal mission_clicked(mission: Variant)
signal mission_started(mission: Variant)

var city_zones: Dictionary = {
	"industrial": {"x": 0.20, "y": 0.25, "width": 0.40, "height": 0.50},  
	"downtown": {"x": 0.55, "y": 0.25, "width": 0.30, "height": 0.50},   
	"park": {"x": 0.85, "y": 0.25, "width": 0.30, "height": 0.50},
	"waterfront": {"x": 0.20, "y": 0.75, "width": 0.40, "height": 0.50},
	"residential": {"x": 0.70, "y": 0.75, "width": 0.60, "height": 0.50}
}

func _ready() -> void:
	print("MissionMap _ready() called")
	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_create_map_ui()
	
	await get_tree().process_frame
	await get_tree().process_frame
	if map_canvas:
		print("MissionMap layout ready, size: %s" % map_canvas.size)
		_refresh_all()

func setup(gm: Node) -> void:
	print("MissionMap setup() called")
	game_manager = gm

func _create_map_ui() -> void:
	print("MissionMap _create_map_ui() called")
	map_canvas = Control.new()
	map_canvas.name = "MapCanvas"
	map_canvas.set_anchors_preset(PRESET_FULL_RECT)
	add_child(map_canvas)
	
	var bg := ColorRect.new()
	bg.color = Color("#1a1a2e")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.z_index = -100
	map_canvas.add_child(bg)
	
	_create_detail_panel()

func refresh_missions() -> void:
	print("refresh_missions() called")
	if not is_inside_tree() or not map_canvas:
		print("  Not ready yet, skipping")
		return
	
	if map_canvas.size.x <= 0 or map_canvas.size.y <= 0:
		print("  Map canvas size invalid: %s, waiting..." % map_canvas.size)
		await get_tree().process_frame
		await get_tree().process_frame
	
	print("  Calling _refresh_all")
	call_deferred("_refresh_all")
	
# Part 2 - Add after Part 1

func _refresh_all() -> void:
	await get_tree().process_frame
	
	print("MissionMap _refresh_all() called")
	
	var current_size = map_canvas.size
	print("  Map canvas size: %s" % current_size)
	
	var need_redraw_zones = true
	var first_zone = map_canvas.get_node_or_null("Zone_downtown")
	if first_zone and abs(current_size.x - map_canvas.size.x) < 10:
		need_redraw_zones = false
		print("  Keeping existing zones and roads (size unchanged)")
	
	if need_redraw_zones:
		for child in map_canvas.get_children():
			if child.name.begins_with("Zone_") or child.name.begins_with("Border_") or child.name.begins_with("Label_") or child.name.begins_with("ChaosDisplay_"):
				child.queue_free()
		
		_draw_zones(current_size.x, current_size.y)
	else:
		_update_chaos_displays()
	
	for marker in mission_markers.values():
		marker.queue_free()
	mission_markers.clear()
	used_positions.clear()
	
	if game_manager:
		var total_missions = game_manager.active_missions.size() + game_manager.available_missions.size()
		print("  Creating markers for %d missions" % total_missions)
		for mission in game_manager.active_missions + game_manager.available_missions:
			_create_mission_marker(mission, mission.is_active)
	else:
		print("  ERROR: game_manager is NULL!")

func _draw_zones(w: float, h: float) -> void:
	print("  Drawing zones with size: %s x %s" % [w, h])
	
	var chaos_info = {}
	if game_manager and game_manager.has_method("get_zone_chaos_info"):
		chaos_info = game_manager.get_zone_chaos_info()
	
	for zone_name in city_zones:
		var z: Dictionary = city_zones[zone_name]
		var cx: float = z.x * w
		var cy: float = z.y * h
		var zw: float = z.width * w
		var zh: float = z.height * h
		var zx: float = cx - zw * 0.5
		var zy: float = cy - zh * 0.5
		
		var rect := ColorRect.new()
		rect.name = "Zone_" + zone_name
		rect.position = Vector2(zx, zy)
		rect.size = Vector2(zw, zh)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var base_color: Color
		match zone_name:
			"downtown":
				base_color = Color(1.0, 0.42, 0.42, 0.5)
			"industrial":
				base_color = Color(1.0, 0.84, 0.0, 0.5)
			"residential":
				base_color = Color(0.3, 0.8, 0.64, 0.5)
			"park":
				base_color = Color(0.32, 0.81, 0.4, 0.5)
			"waterfront":
				base_color = Color(0.0, 0.85, 1.0, 0.5)
			_:
				base_color = Color(0.5, 0.5, 0.5, 0.5)
		
		if chaos_info.has(zone_name):
			var chaos_level = chaos_info[zone_name].level
			var chaos_color = chaos_info[zone_name].color
			var chaos_intensity = chaos_level / 100.0
			rect.color = base_color.lerp(chaos_color.darkened(0.3), chaos_intensity * 0.6)
		else:
			rect.color = base_color
		
		map_canvas.add_child(rect)
		
		var border := ReferenceRect.new()
		border.name = "Border_" + zone_name
		border.position = Vector2(zx, zy)
		border.size = Vector2(zw, zh)
		border.border_color = Color(1, 1, 1, 0.7)
		border.border_width = 3.0
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_canvas.add_child(border)
		
		var label := Label.new()
		label.name = "Label_" + zone_name
		label.text = zone_name.to_upper()
		label.position = Vector2(zx + 20, zy + 20)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_canvas.add_child(label)
		
		if chaos_info.has(zone_name):
			_create_zone_chaos_display(zone_name, chaos_info[zone_name], Vector2(zx, zy), zw)

# Part 3 - Add after Part 2

func _create_zone_chaos_display(zone_name: String, chaos_data: Dictionary, zone_pos: Vector2, zone_width: float) -> void:
	var chaos_level = chaos_data.level
	var chaos_tier = chaos_data.tier
	var chaos_color = chaos_data.color
	
	var panel := PanelContainer.new()
	panel.name = "ChaosDisplay_" + zone_name
	panel.position = Vector2(zone_pos.x + 20, zone_pos.y + 55)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.7)
	panel_style.set_corner_radius_all(5)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 5
	panel_style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)
	
	var tier_label := Label.new()
	var emoji = ""
	match chaos_tier:
		"CRITICAL":
			emoji = "🚨 "
		"HIGH":
			emoji = "💥 "
		"MEDIUM":
			emoji = "🔥 "
		"LOW":
			emoji = "⚠️ "
		"STABLE":
			emoji = "✅ "
	
	tier_label.text = emoji + chaos_tier
	tier_label.add_theme_font_size_override("font_size", 14)
	tier_label.add_theme_color_override("font_color", chaos_color)
	vbox.add_child(tier_label)
	
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(min(120, zone_width - 60), 12)
	bar_bg.color = Color(0.2, 0.2, 0.2, 0.9)
	vbox.add_child(bar_bg)
	
	var bar_fill := ColorRect.new()
	bar_fill.name = "ChaosBar_" + zone_name
	var bar_width = (chaos_level / 100.0) * bar_bg.custom_minimum_size.x
	bar_fill.custom_minimum_size = Vector2(bar_width, 12)
	bar_fill.size = Vector2(bar_width, 12)
	bar_fill.color = chaos_color
	bar_fill.position = Vector2(0, 0)
	bar_bg.add_child(bar_fill)
	
	var percent_label := Label.new()
	percent_label.text = "%.0f%%" % chaos_level
	percent_label.add_theme_font_size_override("font_size", 11)
	percent_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	vbox.add_child(percent_label)
	
	map_canvas.add_child(panel)
	panel.z_index = 5

func _update_chaos_displays() -> void:
	if not game_manager or not game_manager.has_method("get_zone_chaos_info"):
		return
	
	var chaos_info = game_manager.get_zone_chaos_info()
	
	for zone_name in chaos_info.keys():
		var display = map_canvas.get_node_or_null("ChaosDisplay_" + zone_name)
		if not display:
			continue
		
		var chaos_data = chaos_info[zone_name]
		var chaos_level = chaos_data.level
		var chaos_tier = chaos_data.tier
		var chaos_color = chaos_data.color
		
		var vbox = display.get_child(0)
		if vbox:
			var tier_label = vbox.get_child(0)
			if tier_label:
				var emoji = ""
				match chaos_tier:
					"CRITICAL":
						emoji = "🚨 "
					"HIGH":
						emoji = "💥 "
					"MEDIUM":
						emoji = "🔥 "
					"LOW":
						emoji = "⚠️ "
					"STABLE":
						emoji = "✅ "
				tier_label.text = emoji + chaos_tier
				tier_label.add_theme_color_override("font_color", chaos_color)
			
			var bar_bg = vbox.get_child(1)
			if bar_bg:
				var bar_fill = bar_bg.get_node_or_null("ChaosBar_" + zone_name)
				if bar_fill:
					var bar_width = (chaos_level / 100.0) * bar_bg.custom_minimum_size.x
					bar_fill.custom_minimum_size = Vector2(bar_width, 12)
					bar_fill.size = Vector2(bar_width, 12)
					bar_fill.color = chaos_color
			
			var percent_label = vbox.get_child(2)
			if percent_label:
				percent_label.text = "%.0f%%" % chaos_level
				
			# Part 4 - Add after Part 3

func _create_mission_marker(mission: Variant, active: bool) -> void:
	print("    Creating marker for: %s" % mission.mission_name)
	
	var marker_container := Control.new()
	marker_container.custom_minimum_size = Vector2(MISSION_ICON_SIZE, MISSION_ICON_SIZE + 20)
	var pos := _get_mission_position(mission)
	marker_container.position = pos - Vector2(MISSION_ICON_SIZE / 2, (MISSION_ICON_SIZE + 20) / 2)
	
	var marker := PanelContainer.new()
	marker.custom_minimum_size = Vector2(MISSION_ICON_SIZE, MISSION_ICON_SIZE)
	marker.position = Vector2(0, 0)
	
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(MISSION_ICON_SIZE / 2)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	
	if active:
		style.bg_color = Color("#ff8c42")
		style.border_color = Color("#ff6b6b")
	else:
		style.bg_color = mission.get_difficulty_color()
		style.border_color = Color("#ffffff", 0.9)
	
	marker.add_theme_stylebox_override("panel", style)
	
	var icon := Label.new()
	icon.text = mission.mission_emoji
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 32)
	marker.add_child(icon)
	
	marker_container.add_child(marker)
	
	# Expiry timer label (only for available missions)
	if not active and not mission.is_expired:
		var timer_label := Label.new()
		timer_label.name = "ExpiryTimer"
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.add_theme_font_size_override("font_size", 18)
		timer_label.position = Vector2(0, MISSION_ICON_SIZE + 2)
		timer_label.custom_minimum_size = Vector2(MISSION_ICON_SIZE, 18)
		
		var time_remaining = mission.get_time_until_expiry()
		timer_label.text = "⏱️ %ds" % int(time_remaining)
		
		var expiry_percent = mission.get_expiry_percent()
		if expiry_percent < 25:
			timer_label.add_theme_color_override("font_color", Color("#ff3838"))
		elif expiry_percent < 50:
			timer_label.add_theme_color_override("font_color", Color("#ff8c42"))
		else:
			timer_label.add_theme_color_override("font_color", Color("#ffcc00"))
		
		marker_container.add_child(timer_label)
	
	if active:
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(marker, "scale", Vector2(1.15, 1.15), 0.6)
		tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.6)
	
	marker_container.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_marker_clicked(mission)
	)
	
	marker_container.mouse_entered.connect(func(): 
		marker.modulate = Color(1.3, 1.3, 1.3)
	)
	marker_container.mouse_exited.connect(func(): 
		marker.modulate = Color.WHITE
	)
	
	map_canvas.add_child(marker_container)
	marker_container.z_index = 10
	mission_markers[mission.mission_id] = marker_container

func _get_mission_position(mission: Variant) -> Vector2:
	if used_positions.has(mission.mission_id):
		return used_positions[mission.mission_id]
	
	var zone_name: String = mission.get("zone") if mission.get("zone") else "downtown"
	
	if zone_name == "downtown":
		var n: String = mission.mission_name.to_lower()
		if "rescue" in n or "fire" in n:
			zone_name = "residential"
		elif "cyber" in n or "tech" in n or "bomb" in n or "traffic" in n:
			zone_name = "industrial"
		elif "cat" in n or "pet" in n:
			zone_name = "park"
		elif "bank" in n or "robbery" in n or "villain" in n or "gang" in n or "museum" in n:
			zone_name = "downtown"
		elif "bridge" in n or "hostage" in n or "waterfront" in n:
			zone_name = "waterfront"
	
	var zone: Dictionary = city_zones[zone_name]
	var w: float = map_canvas.size.x
	var h: float = map_canvas.size.y
	var cx: float = zone.x * w
	var cy: float = zone.y * h
	var zw: float = zone.width * w
	var zh: float = zone.height * h
	
	var rng := RandomNumberGenerator.new()
	rng.seed = mission.mission_id.hash()
	
	for _i in range(30):
		var x: float = cx + (rng.randf() - 0.5) * (zw - MISSION_ICON_SIZE * 2)
		var y: float = cy + (rng.randf() - 0.5) * (zh - MISSION_ICON_SIZE * 2)
		var pos := Vector2(x, y)
		var ok := true
		for p in used_positions.values():
			if pos.distance_to(p) < MISSION_ICON_SIZE * 2:
				ok = false
				break
		if ok:
			used_positions[mission.mission_id] = pos
			return pos
	
	var fallback := Vector2(cx, cy)
	used_positions[mission.mission_id] = fallback
	return fallback

# Part 5 - Add after Part 4

func _create_detail_panel() -> void:
	mission_detail_panel = PanelContainer.new()
	mission_detail_panel.visible = false
	mission_detail_panel.custom_minimum_size = Vector2(360, 340)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16213e")
	style.set_corner_radius_all(12)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color("#00d9ff")
	mission_detail_panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	mission_detail_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	detail_name_label = Label.new()
	detail_name_label.add_theme_font_size_override("font_size", 22)
	detail_name_label.add_theme_color_override("font_color", Color("#00d9ff"))
	detail_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(detail_name_label)
	
	detail_close_button = Button.new()
	detail_close_button.text = "X"
	detail_close_button.custom_minimum_size = Vector2(30, 30)
	detail_close_button.pressed.connect(_on_detail_close_pressed)
	header.add_child(detail_close_button)
	
	detail_difficulty_label = Label.new()
	detail_difficulty_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(detail_difficulty_label)
	vbox.add_child(HSeparator.new())
	
	detail_description_label = Label.new()
	detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(detail_description_label)
	
	detail_rewards_label = Label.new()
	detail_rewards_label.add_theme_color_override("font_color", Color("#4ecca3"))
	vbox.add_child(detail_rewards_label)
	
	detail_requirements_label = Label.new()
	detail_requirements_label.add_theme_color_override("font_color", Color("#a8a8a8"))
	vbox.add_child(detail_requirements_label)
	
	detail_assigned_label = Label.new()
	vbox.add_child(detail_assigned_label)
	
	var timer_box := VBoxContainer.new()
	vbox.add_child(timer_box)
	detail_timer_label = Label.new()
	detail_timer_label.visible = false
	timer_box.add_child(detail_timer_label)
	
	detail_timer_progress = ProgressBar.new()
	detail_timer_progress.visible = false
	detail_timer_progress.custom_minimum_size = Vector2(0, 20)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#2d2d44")
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#00d9ff")
	detail_timer_progress.add_theme_stylebox_override("background", bg_style)
	detail_timer_progress.add_theme_stylebox_override("fill", fill_style)
	timer_box.add_child(detail_timer_progress)
	
	detail_start_button = Button.new()
	detail_start_button.text = "START MISSION"
	detail_start_button.custom_minimum_size = Vector2(0, 44)
	detail_start_button.pressed.connect(_on_detail_start_pressed)
	vbox.add_child(detail_start_button)
	
	add_child(mission_detail_panel)
	mission_detail_panel.z_index = 100

func _on_marker_clicked(mission: Variant) -> void:
	print("\n!!! _on_marker_clicked called !!!")
	print("  Mission: %s" % mission.mission_name)
	
	selected_mission = mission
	mission_clicked.emit(mission)
	
	var marker = mission_markers[mission.mission_id]
	var center = marker.position + Vector2(MISSION_ICON_SIZE / 2, MISSION_ICON_SIZE / 2)
	
	var x: float = center.x + 40
	var y: float = center.y - 170
	if x + 360 > map_canvas.size.x:
		x = center.x - 400
	x = clamp(x, 10, map_canvas.size.x - 370)
	y = clamp(y, 10, map_canvas.size.y - 350)
	
	mission_detail_panel.position = Vector2(x, y)
	mission_detail_panel.visible = true
	_update_detail_panel()
	
# Part 6 - Add after Part 5 (FINAL PART)

func _update_detail_panel() -> void:
	if not selected_mission:
		return
	
	detail_name_label.text = "%s %s" % [selected_mission.mission_emoji, selected_mission.mission_name]
	detail_difficulty_label.text = selected_mission.get_difficulty_string()
	detail_difficulty_label.add_theme_color_override("font_color", selected_mission.get_difficulty_color())
	detail_description_label.text = selected_mission.description
	detail_rewards_label.text = "$%d | %d Fame" % [selected_mission.money_reward, selected_mission.fame_reward]
	detail_requirements_label.text = selected_mission.get_requirements_text()
	
	var names: Array[String] = []
	for id in selected_mission.assigned_hero_ids:
		var hero = game_manager.get_hero_by_id(id) if game_manager else null
		if hero:
			names.append(hero.hero_name)
	detail_assigned_label.text = "Assigned: " + (", ".join(names) if not names.is_empty() else "None")
	
	if selected_mission.is_active:
		detail_timer_label.visible = true
		detail_timer_progress.visible = true
		detail_start_button.visible = false
		_update_timer_display()
	elif selected_mission.is_expired:
		detail_timer_label.visible = false
		detail_timer_progress.visible = false
		detail_start_button.visible = true
		detail_start_button.disabled = true
		detail_start_button.text = "MISSION EXPIRED"
	else:
		_update_expiry_display()

func _update_expiry_display() -> void:
	if not selected_mission or selected_mission.is_active or selected_mission.is_expired:
		return
	
	var time_until_expiry = selected_mission.get_time_until_expiry()
	var expiry_percent = selected_mission.get_expiry_percent()
	
	detail_timer_label.visible = true
	detail_timer_label.text = "⏱️ Expires in: %ds" % int(time_until_expiry)
	
	if expiry_percent < 25:
		detail_timer_label.add_theme_color_override("font_color", Color("#ff3838"))
	elif expiry_percent < 50:
		detail_timer_label.add_theme_color_override("font_color", Color("#ff8c42"))
	else:
		detail_timer_label.add_theme_color_override("font_color", Color("#ffcc00"))
	
	detail_timer_progress.visible = true
	detail_timer_progress.max_value = selected_mission.availability_timeout
	detail_timer_progress.value = selected_mission.availability_timer
	
	var fill_style = detail_timer_progress.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		if expiry_percent < 25:
			fill_style.bg_color = Color("#ff3838")
		elif expiry_percent < 50:
			fill_style.bg_color = Color("#ff8c42")
		else:
			fill_style.bg_color = Color("#ffcc00")
	
	detail_start_button.visible = true
	detail_start_button.disabled = not selected_mission.can_start()
	detail_start_button.text = "START MISSION" if selected_mission.can_start() else "ASSIGN HEROES FIRST"

func refresh_detail_panel() -> void:
	if mission_detail_panel and mission_detail_panel.visible:
		_update_detail_panel()

func _update_timer_display() -> void:
	if not selected_mission or not selected_mission.is_active:
		return
	var mins: int = int(selected_mission.time_remaining) / 60
	var secs: int = int(selected_mission.time_remaining) % 60
	detail_timer_label.text = "Time: %02d:%02d" % [mins, secs]
	detail_timer_progress.max_value = selected_mission.base_duration
	detail_timer_progress.value = selected_mission.base_duration - selected_mission.time_remaining

func _process(_delta: float) -> void:
	if mission_detail_panel.visible and selected_mission:
		if selected_mission.is_active:
			_update_timer_display()
		elif not selected_mission.is_expired:
			_update_expiry_display()
	
	# Update expiry timers on mission markers
	for mission_id in mission_markers.keys():
		var marker = mission_markers[mission_id]
		var timer_label = marker.get_node_or_null("ExpiryTimer")
		
		if timer_label:
			var mission = null
			for m in game_manager.available_missions:
				if m.mission_id == mission_id:
					mission = m
					break
			
			if mission and not mission.is_expired:
				var time_remaining = mission.get_time_until_expiry()
				timer_label.text = "⏱️ %ds" % int(time_remaining)
				
				var expiry_percent = mission.get_expiry_percent()
				if expiry_percent < 25:
					timer_label.add_theme_color_override("font_color", Color("#ff3838"))
				elif expiry_percent < 50:
					timer_label.add_theme_color_override("font_color", Color("#ff8c42"))
				else:
					timer_label.add_theme_color_override("font_color", Color("#ffcc00"))
	
	_update_chaos_displays()

func _on_detail_close_pressed() -> void:
	mission_detail_panel.visible = false
	selected_mission = null

func _on_detail_start_pressed() -> void:
	print("Detail start button pressed")
	if selected_mission:
		print("  Emitting mission_started signal for: %s" % selected_mission.mission_name)
		mission_started.emit(selected_mission)

func close_detail_panel() -> void:
	if mission_detail_panel:
		mission_detail_panel.visible = false
	selected_mission = null
