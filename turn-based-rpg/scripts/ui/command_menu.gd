class_name CommandMenu
extends VBoxContainer

## displays action buttons for the current character.
## show_commands() → player clicks a button → signal emitted → hide

signal attack_selected()
signal magic_selected()
signal defend_selected()
signal item_selected()
signal charge_selected()
signal move_selected(move: MoveData)

var current_combatant: Combatant = null

# references to sub-menus (set in _ready or by parent)
@export var magic_submenu: VBoxContainer = null

# track whether we're in the main menu or a sub-menu
var in_submenu: bool = false


func _ready() -> void:
	visible = false


func show_commands(combatant: Combatant) -> void:
	## show the command menu for a specific character.
	current_combatant = combatant
	in_submenu = false
	_clear_children()
	
	# title label
	var title = Label.new()
	title.text = "%s's Turn" % combatant.get_character_name()
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	# check if this character has any PHYSICAL moves
	var has_physical = combatant.base_data.moves.any(func(m):
		return m.move_type == MoveData.MoveType.PHYSICAL
	)
	if has_physical:
		var btn = _make_button("Attack", func(): _show_attack_submenu())
		add_child(btn)
	
	#checks for MAGICAL moves
	var magic_moves = combatant.base_data.moves.filter(func(m):
		return m.move_type == MoveData.MoveType.MAGICAL or m.move_type == MoveData.MoveType.HEAL
	)
	if not magic_moves.is_empty():
		var btn = _make_button("Magic", func(): _show_magic_submenu(magic_moves))
		add_child(btn)
	
	
	var btn_defend = _make_button("Defend", func(): defend_selected.emit())
	add_child(btn_defend)
	
	var btn_item = _make_button("Item", func(): item_selected.emit())
	add_child(btn_item)
	
	var btn_charge = _make_button("Charge", func(): charge_selected.emit())
	add_child(btn_charge)
	
	visible = true


func _show_attack_submenu() -> void:
	## show physical attack moves for this character.
	in_submenu = true
	_clear_children()
	
	var title = Label.new()
	title.text = "Choose Attack:"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	add_child(title)
	
	var physical_moves = current_combatant.base_data.moves.filter(func(m):
		return m.move_type == MoveData.MoveType.PHYSICAL
	)
	
	for move in physical_moves:
		var can_afford = current_combatant.can_afford_move(move)
		var label_text = "%s (Pow:%d)" % [move.move_name, move.power]
		if move.mp_cost > 0:
			label_text += " [%dMP]" % move.mp_cost
		
		var btn = _make_button(label_text, func(): move_selected.emit(move))
		btn.disabled = not can_afford
		if not can_afford:
			btn.modulate = Color(0.5, 0.5, 0.5)
		add_child(btn)
	
	# back button
	var back_btn = _make_button("← Back", func(): show_commands(current_combatant))
	add_child(back_btn)


func _show_magic_submenu(magic_moves: Array) -> void:
	## show magical/heal moves for this character.
	in_submenu = true
	_clear_children()
	
	var title = Label.new()
	title.text = "Choose Spell:"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	add_child(title)
	
	for move in magic_moves:
		var can_afford = current_combatant.can_afford_move(move)
		var label_text = "%s (Pow:%d) [%dMP]" % [move.move_name, move.power, move.mp_cost]
		
		var btn = _make_button(label_text, func(): move_selected.emit(move))
		btn.disabled = not can_afford
		if not can_afford:
			btn.modulate = Color(0.5, 0.5, 0.5)
		add_child(btn)
	
	# back button
	var back_btn = _make_button("← Back", func(): show_commands(current_combatant))
	add_child(back_btn)


func hide_menu() -> void:
	visible = false
	_clear_children()


func _make_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(200, 36)
	btn.pressed.connect(callback)
	
	# style the button
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
