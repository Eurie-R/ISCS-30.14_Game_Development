class_name TargetSelector
extends VBoxContainer

##displays target buttons for the player to pick who to attack/heal.

signal target_selected(target: Combatant)
signal cancelled()


func _ready() -> void:
	visible = false


func show_targets(targets: Array, prompt: String = "Choose Target:") -> void:
	##display buttons for each valid target.
	_clear_children()
	
	#prompt label
	var title = Label.new()
	title.text = prompt
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	add_child(title)
	
	for target in targets:
		if target is Combatant and target.is_alive():
			var hp_text = "HP: %d/%d" % [target.current_hp, target.base_data.max_hp]
			var label_text = "%s (%s)" % [target.get_character_name(), hp_text]
			
			var btn = _make_button(label_text, func(): _on_target_picked(target))
			
			# Color-code: enemies in red-ish, allies in green-ish
			if not target.is_player():
				var style = btn.get_theme_stylebox("normal").duplicate()
				style.bg_color = Color(0.25, 0.1, 0.1, 0.9)
				style.border_color = Color(0.6, 0.3, 0.3)
				btn.add_theme_stylebox_override("normal", style)
			else:
				var style = btn.get_theme_stylebox("normal").duplicate()
				style.bg_color = Color(0.1, 0.2, 0.15, 0.9)
				style.border_color = Color(0.3, 0.6, 0.4)
				btn.add_theme_stylebox_override("normal", style)
			
			add_child(btn)
	
	#cancel/back button
	var back_btn = _make_button("← Cancel", func(): cancelled.emit())
	add_child(back_btn)
	
	visible = true


func hide_selector() -> void:
	visible = false
	_clear_children()


func _on_target_picked(target: Combatant) -> void:
	target_selected.emit(target)


func _make_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(220, 36)
	btn.pressed.connect(callback)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.25, 0.25, 0.45, 0.95)
	hover_style.border_color = Color(0.6, 0.6, 1.0)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	
	return btn


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
