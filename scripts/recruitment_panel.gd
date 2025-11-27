# res://scripts/recruitment_panel.gd
extends CanvasLayer

var game_manager: Node
var recruitment_system: RecruitmentSystem

# UI References
var overlay: ColorRect
var panel: PanelContainer
var close_button: Button
var standard_button: Button
var premium_button: Button
var standard_cost_label: Label
var premium_cost_label: Label
var pity_label: Label

# Reveal animation
var reveal_panel: PanelContainer
var reveal_hero_emoji: Label
var reveal_hero_name: Label
var reveal_rarity: Label
var reveal_stats: VBoxContainer
var reveal_close_button: Button

func _ready() -> void:
	visible = false
	_create_ui()

func setup(gm: Node, recruitment: RecruitmentSystem) -> void:
	game_manager = gm
	recruitment_system = recruitment
	
	# Connect signals
	if recruitment_system:
		recruitment_system.hero_recruited.connect(_on_hero_recruited)
		recruitment_system.recruitment_failed.connect(_on_recruitment_failed)

func _create_ui() -> void:
	# Overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			hide_panel()
	)
	
	# Main Panel
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 500)
	center.add_child(panel)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16213e")
	style.set_corner_radius_all(15)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color("#00d9ff")
	panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var title := Label.new()
	title.text = "🎰 HERO RECRUITMENT"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#00d9ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(hide_panel)
	header.add_child(close_button)
	
	vbox.add_child(HSeparator.new())
	
	# Description
	var desc := Label.new()
	desc.text = "Recruit new heroes to expand your team!\nHigher tier recruits have better chances for rare heroes."
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("#a8a8a8"))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	# Pity Counter
	pity_label = Label.new()
	pity_label.text = "Premium Pity: 0/10 (Guaranteed Epic at 10)"
	pity_label.add_theme_font_size_override("font_size", 14)
	pity_label.add_theme_color_override("font_color", Color("#ffcc00"))
	pity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pity_label)
	
	# Recruitment options
	var recruit_container := HBoxContainer.new()
	recruit_container.add_theme_constant_override("separation", 30)
	recruit_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(recruit_container)
	
	# Standard Recruit
	var standard_box := _create_recruit_option(
		"Standard Recruit",
		"60% Common\n30% Rare\n9% Epic\n1% Legendary",
		RecruitmentSystem.STANDARD_RECRUIT_COST,
		false
	)
	recruit_container.add_child(standard_box)
	
	# Premium Recruit
	var premium_box := _create_recruit_option(
		"Premium Recruit",
		"0% Common\n40% Rare\n50% Epic\n10% Legendary",
		RecruitmentSystem.PREMIUM_RECRUIT_COST,
		true
	)
	recruit_container.add_child(premium_box)
	
	# Info
	var info := Label.new()
	info.text = "💡 Tip: Premium recruits have guaranteed Epic or better every 10 pulls!"
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color("#4ecca3"))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)
	
	# Create reveal panel (hidden by default)
	_create_reveal_panel()

func _create_recruit_option(title: String, rates: String, cost: int, is_premium: bool) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(250, 300)
	vbox.add_theme_constant_override("separation", 10)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0f1624") if not is_premium else Color("#1a0f24")
	panel_style.set_corner_radius_all(10)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color("#4ecca3") if not is_premium else Color("#9c27b0")
	
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(container)
	
	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 10)
	container.add_child(inner_vbox)
	
	var inner_margin := MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 15)
	inner_margin.add_theme_constant_override("margin_right", 15)
	inner_margin.add_theme_constant_override("margin_top", 15)
	inner_margin.add_theme_constant_override("margin_bottom", 15)
	inner_vbox.add_child(inner_margin)
	
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	inner_margin.add_child(content)
	
	# Title
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("#00d9ff"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title_label)
	
	content.add_child(HSeparator.new())
	
	# Rates
	var rates_label := Label.new()
	rates_label.text = rates
	rates_label.add_theme_font_size_override("font_size", 14)
	rates_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(rates_label)
	
	# Cost
	var cost_label := Label.new()
	cost_label.text = "💰 $%d" % cost
	cost_label.add_theme_font_size_override("font_size", 18)
	cost_label.add_theme_color_override("font_color", Color("#ffcc00"))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(cost_label)
	
	if is_premium:
		premium_cost_label = cost_label
	else:
		standard_cost_label = cost_label
	
	# Button
	var button := Button.new()
	button.text = "RECRUIT"
	button.custom_minimum_size = Vector2(0, 50)
	button.add_theme_font_size_override("font_size", 18)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#4ecca3") if not is_premium else Color("#9c27b0")
	btn_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color("#45b393") if not is_premium else Color("#7b1fa2")
	btn_hover.set_corner_radius_all(8)
	button.add_theme_stylebox_override("hover", btn_hover)
	
	content.add_child(button)
	
	if is_premium:
		premium_button = button
		button.pressed.connect(_on_premium_recruit_pressed)
	else:
		standard_button = button
		button.pressed.connect(_on_standard_recruit_pressed)
	
	return vbox

func _create_reveal_panel() -> void:
	reveal_panel = PanelContainer.new()
	reveal_panel.visible = false
	reveal_panel.set_anchors_preset(Control.PRESET_CENTER)
	reveal_panel.custom_minimum_size = Vector2(400, 500)
	add_child(reveal_panel)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a0a0a")
	style.set_corner_radius_all(15)
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.border_color = Color("#ffcc00")
	reveal_panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	reveal_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# NEW HERO!
	var new_label := Label.new()
	new_label.text = "✨ NEW HERO RECRUITED! ✨"
	new_label.add_theme_font_size_override("font_size", 24)
	new_label.add_theme_color_override("font_color", Color("#ffcc00"))
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(new_label)
	
	vbox.add_child(HSeparator.new())
	
	# Hero emoji (big)
	reveal_hero_emoji = Label.new()
	reveal_hero_emoji.text = "🦸"
	reveal_hero_emoji.add_theme_font_size_override("font_size", 128)
	reveal_hero_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reveal_hero_emoji)
	
	# Hero name
	reveal_hero_name = Label.new()
	reveal_hero_name.text = "Hero Name"
	reveal_hero_name.add_theme_font_size_override("font_size", 32)
	reveal_hero_name.add_theme_color_override("font_color", Color("#00d9ff"))
	reveal_hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reveal_hero_name)
	
	# Rarity
	reveal_rarity = Label.new()
	reveal_rarity.text = "★ LEGENDARY ★"
	reveal_rarity.add_theme_font_size_override("font_size", 20)
	reveal_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reveal_rarity)
	
	vbox.add_child(HSeparator.new())
	
	# Stats
	reveal_stats = VBoxContainer.new()
	reveal_stats.add_theme_constant_override("separation", 5)
	vbox.add_child(reveal_stats)
	
	# Close button
	reveal_close_button = Button.new()
	reveal_close_button.text = "AWESOME!"
	reveal_close_button.custom_minimum_size = Vector2(0, 50)
	reveal_close_button.add_theme_font_size_override("font_size", 20)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#4ecca3")
	btn_style.set_corner_radius_all(8)
	reveal_close_button.add_theme_stylebox_override("normal", btn_style)
	
	reveal_close_button.pressed.connect(_on_reveal_close_pressed)
	vbox.add_child(reveal_close_button)

func show_panel() -> void:
	visible = true
	_update_costs()
	_update_pity_label()

func hide_panel() -> void:
	visible = false

func _update_costs() -> void:
	if not game_manager:
		return
	
	# Update button states based on affordability
	if standard_button:
		standard_button.disabled = not recruitment_system.can_afford_recruit(false)
	if premium_button:
		premium_button.disabled = not recruitment_system.can_afford_recruit(true)

func _update_pity_label() -> void:
	if pity_label and recruitment_system:
		var pity = recruitment_system.premium_pity_counter
		pity_label.text = "Premium Pity: %d/10 (Guaranteed Epic at 10)" % pity
		
		if pity >= RecruitmentSystem.PREMIUM_PITY_THRESHOLD:
			pity_label.add_theme_color_override("font_color", Color("#ff3838"))
		else:
			pity_label.add_theme_color_override("font_color", Color("#ffcc00"))

func _on_standard_recruit_pressed() -> void:
	if recruitment_system:
		recruitment_system.standard_recruit()
		_update_costs()
		_update_pity_label()

func _on_premium_recruit_pressed() -> void:
	if recruitment_system:
		recruitment_system.premium_recruit()
		_update_costs()
		_update_pity_label()

func _on_hero_recruited(hero: Hero, rarity: RecruitmentSystem.Rarity) -> void:
	# Hide main panel
	panel.visible = false
	
	# Show reveal panel
	reveal_panel.visible = true
	reveal_panel.position = get_viewport().get_visible_rect().size / 2 - reveal_panel.size / 2
	
	# Update reveal panel
	reveal_hero_emoji.text = hero.hero_emoji
	reveal_hero_name.text = hero.hero_name
	
	var rarity_text = ""
	var rarity_color = Color.WHITE
	match rarity:
		RecruitmentSystem.Rarity.COMMON:
			rarity_text = "★ COMMON ★"
			rarity_color = Color("#9e9e9e")
		RecruitmentSystem.Rarity.RARE:
			rarity_text = "★★ RARE ★★"
			rarity_color = Color("#4caf50")
		RecruitmentSystem.Rarity.EPIC:
			rarity_text = "★★★ EPIC ★★★"
			rarity_color = Color("#9c27b0")
		RecruitmentSystem.Rarity.LEGENDARY:
			rarity_text = "★★★★ LEGENDARY ★★★★"
			rarity_color = Color("#ff9800")
	
	reveal_rarity.text = rarity_text
	reveal_rarity.add_theme_color_override("font_color", rarity_color)
	
	# Update stats
	for child in reveal_stats.get_children():
		child.queue_free()
	
	var stats = [
		"💪 Strength: %d" % hero.get_total_strength(),
		"⚡ Speed: %d" % hero.get_total_speed(),
		"🧠 Intelligence: %d" % hero.get_total_intelligence(),
		"❤️ Health: %d" % hero.max_health,
		"⚡ Stamina: %d" % hero.max_stamina
	]
	
	for stat_text in stats:
		var stat_label := Label.new()
		stat_label.text = stat_text
		stat_label.add_theme_font_size_override("font_size", 16)
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reveal_stats.add_child(stat_label)
	
	# Play sound effect (if you have one)
	# AudioManager.play_sound("hero_recruited")
	
	# Animate panel
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	reveal_panel.scale = Vector2(0.5, 0.5)
	tween.tween_property(reveal_panel, "scale", Vector2(1, 1), 0.5)

func _on_reveal_close_pressed() -> void:
	reveal_panel.visible = false
	panel.visible = true
	
	# Refresh hero list in main game
	if game_manager and game_manager.has_signal("heroes_changed"):
		game_manager.emit_signal("heroes_changed")

func _on_recruitment_failed(reason: String) -> void:
	if game_manager and game_manager.has_method("update_status"):
		game_manager.update_status("❌ " + reason)
