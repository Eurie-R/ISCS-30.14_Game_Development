class_name BattleHUD
extends Control

## manages HP/MP bar displays for all combatants.
## dynamically creates status panels for each character.

# {Combatant: PanelContainer}
var player_panels: Dictionary = {}
var enemy_panels: Dictionary = {}    

@onready var player_container: HBoxContainer = null
@onready var enemy_container: HBoxContainer = null


func setup_hud(player_party: Array, enemy_party: Array) -> void:
	## create HP/MP panels for all characters.
	_clear_all()
	
	for combatant in player_party:
		var panel = _create_character_panel(combatant, true)
		player_container.add_child(panel)
		player_panels[combatant] = panel
		# connect signals
		combatant.hp_changed.connect(func(hp, max_hp): _update_hp(combatant, hp, max_hp))
		combatant.mp_changed.connect(func(mp, max_mp): _update_mp(combatant, mp, max_mp))
		combatant.defeated.connect(func(): _on_defeated(combatant))
	
	for combatant in enemy_party:
		var panel = _create_character_panel(combatant, false)
		enemy_container.add_child(panel)
		enemy_panels[combatant] = panel
		combatant.hp_changed.connect(func(hp, max_hp): _update_hp(combatant, hp, max_hp))
		combatant.defeated.connect(func(): _on_defeated(combatant))


func _create_character_panel(combatant: Combatant, show_mp: bool) -> PanelContainer:
	## build a panel with name label, HP bar, and optionally MP bar.
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 0)
	
	# panel background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.18, 0.85)
	style.border_color = Color(0.3, 0.3, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	#character name
	var name_label = Label.new()
	name_label.text = combatant.get_character_name()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	#hp label
	var hp_label = Label.new()
	hp_label.text = "HP: %d / %d" % [combatant.current_hp, combatant.base_data.max_hp]
	hp_label.name = "HPLabel"
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hp_label)
	
	#hp bar
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.max_value = combatant.base_data.max_hp
	hp_bar.value = combatant.current_hp
	hp_bar.custom_minimum_size = Vector2(0, 16)
	hp_bar.show_percentage = false
	
	#hp bar style
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.05, 0.05)
	bar_bg.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.8, 0.2)
	bar_fill.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("fill", bar_fill)
	
	vbox.add_child(hp_bar)
	
	#mp bar (only for players)
	if show_mp:
		var mp_label = Label.new()
		mp_label.text = "MP: %d / %d" % [combatant.current_mp, combatant.base_data.max_mp]
		mp_label.name = "MPLabel"
		mp_label.add_theme_font_size_override("font_size", 12)
		mp_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
		mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(mp_label)
		
		var mp_bar = ProgressBar.new()
		mp_bar.name = "MPBar"
		mp_bar.max_value = combatant.base_data.max_mp
		mp_bar.value = combatant.current_mp
		mp_bar.custom_minimum_size = Vector2(0, 12)
		mp_bar.show_percentage = false
		
		var mp_bg = StyleBoxFlat.new()
		mp_bg.bg_color = Color(0.05, 0.05, 0.15)
		mp_bg.set_corner_radius_all(3)
		mp_bar.add_theme_stylebox_override("background", mp_bg)
		
		var mp_fill = StyleBoxFlat.new()
		mp_fill.bg_color = Color(0.3, 0.4, 0.9)
		mp_fill.set_corner_radius_all(3)
		mp_bar.add_theme_stylebox_override("fill", mp_fill)
		
		vbox.add_child(mp_bar)
	
	return panel


func _update_hp(combatant: Combatant, new_hp: int, max_hp: int) -> void:
	var panels = player_panels if combatant.is_player() else enemy_panels
	if not panels.has(combatant):
		return
	
	var panel = panels[combatant]
	var vbox = panel.get_child(0)
	
	var hp_bar = vbox.get_node("HPBar") as ProgressBar
	var hp_label = vbox.get_node("HPLabel") as Label
	
	if hp_bar:
		#smooth tween animation for HP bar
		var tween = create_tween()
		tween.tween_property(hp_bar, "value", float(new_hp), 0.4).set_ease(Tween.EASE_OUT)
		
		#update bar color based on HP percentage
		var ratio = float(new_hp) / float(max_hp)
		var fill_style = hp_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		if ratio > 0.5:
			fill_style.bg_color = Color(0.2, 0.8, 0.2)  # Green
		elif ratio > 0.25:
			fill_style.bg_color = Color(0.9, 0.7, 0.1)  # Yellow
		else:
			fill_style.bg_color = Color(0.9, 0.2, 0.2)  # Red
		hp_bar.add_theme_stylebox_override("fill", fill_style)
	
	if hp_label:
		hp_label.text = "HP: %d / %d" % [new_hp, max_hp]


func _update_mp(combatant: Combatant, new_mp: int, max_mp: int) -> void:
	if not player_panels.has(combatant):
		return
	
	var panel = player_panels[combatant]
	var vbox = panel.get_child(0)
	
	var mp_bar = vbox.get_node_or_null("MPBar") as ProgressBar
	var mp_label = vbox.get_node_or_null("MPLabel") as Label
	
	if mp_bar:
		var tween = create_tween()
		tween.tween_property(mp_bar, "value", float(new_mp), 0.3).set_ease(Tween.EASE_OUT)
	
	if mp_label:
		mp_label.text = "MP: %d / %d" % [new_mp, max_mp]


func _on_defeated(combatant: Combatant) -> void:
	var panels = player_panels if combatant.is_player() else enemy_panels
	if panels.has(combatant):
		var panel = panels[combatant]
		#gray out the panel
		var tween = create_tween()
		tween.tween_property(panel, "modulate", Color(0.4, 0.4, 0.4, 0.6), 0.5)


func _clear_all() -> void:
	for child in player_container.get_children():
		child.queue_free()
	for child in enemy_container.get_children():
		child.queue_free()
	player_panels.clear()
	enemy_panels.clear()
