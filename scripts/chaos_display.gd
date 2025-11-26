# res://scripts/chaos_display.gd
# UI component to display chaos levels in each zone
extends PanelContainer

var game_manager: Node
var zone_bars: Dictionary = {}

func _ready() -> void:
	_create_ui()

func setup(gm: Node) -> void:
	game_manager = gm
	
	if game_manager and game_manager.chaos_system:
		game_manager.chaos_system.chaos_level_changed.connect(_on_chaos_changed)
		_update_display()

func _create_ui() -> void:
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1624")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#00d9ff")
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
	
	custom_minimum_size = Vector2(280, 0)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# Title
	var title := Label.new()
	title.text = "🔥 ZONE CHAOS LEVELS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#ff6b6b"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Create zone displays
	var zones = ["downtown", "industrial", "residential", "park", "waterfront"]
	for zone in zones:
		var zone_container = _create_zone_display(zone)
		vbox.add_child(zone_container)
		zone_bars[zone] = zone_container

func _create_zone_display(zone_name: String) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	
	# Zone name label
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = zone_name.capitalize()
	name_label.add_theme_font_size_override("font_size", 14)
	container.add_child(name_label)
	
	# Progress bar row
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 5)
	container.add_child(bar_row)
	
	# Chaos progress bar
	var progress := ProgressBar.new()
	progress.name = "ProgressBar"
	progress.custom_minimum_size = Vector2(180, 16)
	progress.max_value = 100
	progress.value = 0
	progress.show_percentage = false
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#1a1a2e")
	progress.add_theme_stylebox_override("background", bg_style)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#4ecca3")
	progress.add_theme_stylebox_override("fill", fill_style)
	
	bar_row.add_child(progress)
	
	# Percentage label
	var percent_label := Label.new()
	percent_label.name = "PercentLabel"
	percent_label.text = "0%"
	percent_label.custom_minimum_size = Vector2(45, 0)
	percent_label.add_theme_font_size_override("font_size", 12)
	bar_row.add_child(percent_label)
	
	# Status label (tier)
	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "STABLE"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color("#4ecca3"))
	container.add_child(status_label)
	
	return container

func _update_display() -> void:
	if not game_manager or not game_manager.chaos_system:
		return
	
	var chaos_info = game_manager.get_zone_chaos_info()
	
	for zone_name in zone_bars.keys():
		if not chaos_info.has(zone_name):
			continue
		
		var zone_data = chaos_info[zone_name]
		var container = zone_bars[zone_name]
		
		# Update progress bar
		var progress: ProgressBar = container.get_node("HBoxContainer/ProgressBar")
		if progress:
			progress.value = zone_data.level
			
			# Update color based on chaos level
			var fill_style: StyleBoxFlat = progress.get_theme_stylebox("fill")
			if fill_style:
				fill_style.bg_color = zone_data.color
		
		# Update percentage
		var percent_label: Label = container.get_node("HBoxContainer/PercentLabel")
		if percent_label:
			percent_label.text = "%.0f%%" % zone_data.level
		
		# Update status tier
		var status_label: Label = container.get_node("StatusLabel")
		if status_label:
			status_label.text = zone_data.tier
			status_label.add_theme_color_override("font_color", zone_data.color)
		
		# Update zone name with emoji
		var name_label: Label = container.get_node("NameLabel")
		if name_label:
			var emoji = ""
			match zone_data.tier:
				"CRITICAL":
					emoji = "🚨 "
				"HIGH":
					emoji = "💥 "
				"MEDIUM":
					emoji = "🔥 "
				"LOW":
					emoji = "⚠️ "
			name_label.text = emoji + zone_name.capitalize()

func _on_chaos_changed(_zone: String, _new_level: float) -> void:
	_update_display()

func _process(_delta: float) -> void:
	# Update display periodically
	if game_manager and game_manager.chaos_system:
		_update_display()
