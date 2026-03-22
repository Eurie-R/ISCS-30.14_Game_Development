class_name CharacterDisplay
extends Node2D

## visual representation of a combatant on the battle screen.
## handles sprite display, animations, and effects.

var combatant: Combatant = null
var sprite: Sprite2D = null
var original_position: Vector2 = Vector2.ZERO
var is_enemy: bool = false

# damage number scene reference
var damage_label_scene: PackedScene = null


func setup(p_combatant: Combatant, p_is_enemy: bool) -> void:
	combatant = p_combatant
	is_enemy = p_is_enemy
	original_position = position
	
	# create the sprite node
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	# load the sprite texture from character data
	if combatant.base_data.sprite != null:
		sprite.texture = combatant.base_data.sprite
	else:
		# create a placeholder colored rectangle if no sprite assigned
		_create_placeholder()
	
	# flip enemy sprites to face left (players face right by default)
	if is_enemy:
		sprite.flip_h = true
	
	# connect combatant signals for visual feedback
	combatant.hp_changed.connect(_on_hp_changed)
	combatant.defeated.connect(_on_defeated)
	combatant.status_applied.connect(_on_status_applied)
	combatant.status_removed.connect(_on_status_removed)
	
	# start idle animation
	_start_idle_animation()


func _create_placeholder() -> void:
	## creates a simple colored rectangle as a placeholder sprite.
	## remove this once you have real sprites.
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	var color: Color
	if not is_enemy:
		# players
		if combatant.get_character_name() == "Kael":
			color = Color(0.3, 0.4, 0.8)   # Blue (warrior)
		else:
			color = Color(0.7, 0.3, 0.8)   # Purple (mage)
	else:
		# enemies
		if combatant.get_character_name() == "Shadow Wolf":
			color = Color(0.4, 0.4, 0.5)   # Gray
		else:
			color = Color(0.6, 0.2, 0.2)   # Dark red
	
	image.fill(color)
	
	# addd a simple border
	for x in range(64):
		for y in range(64):
			if x < 2 or x > 61 or y < 2 or y > 61:
				image.set_pixel(x, y, Color(1, 1, 1, 0.5))
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	# add a name label below the placeholder
	var label = Label.new()
	label.text = combatant.get_character_name()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, 36)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)


#animations
func _start_idle_animation() -> void:
	## gentle bobbing up and down while idle.
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func play_attack_animation() -> void:
	## slide forward toward the enemy, then return.
	var direction = 1.0 if not is_enemy else -1.0
	var attack_offset = Vector2(80 * direction, 0)
	
	var tween = create_tween()
	# slide forward
	tween.tween_property(self, "position", original_position + attack_offset, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# hold briefly
	tween.tween_interval(0.1)
	# return to original position
	tween.tween_property(self, "position", original_position, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)


func play_damage_flash() -> void:
	## flash red when taking damage.
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)


func play_heal_effect() -> void:
	## green glow when healed.
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.3)


func play_charge_glow() -> void:
	## blue pulsing glow when charging.
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 0.7, 2.0), 0.3).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "modulate", Color(0.7, 0.85, 1.5), 0.3).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "modulate", Color(0.5, 0.7, 2.0), 0.3).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)


func play_defend_effect() -> void:
	## brief shield shimmer — scales up slightly then back.
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.7, 0.9, 1.5), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)


func show_damage_number(amount: int, is_crit: bool = false, is_heal: bool = false) -> void:
	## spawn a floating number that drifts upward and fades out.
	var label = Label.new()
	
	if is_heal:
		label.text = "+%d" % amount
		label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	elif is_crit:
		label.text = "%d!" % amount
		label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.text = "%d" % amount
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	if not is_crit:
		label.add_theme_font_size_override("font_size", 22)
	
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# random horizontal offset so numbers don't stack
	label.position = Vector2(randf_range(-20, 20), -40)
	add_child(label)
	
	# float up and fade out
	var tween = create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


func show_miss_text() -> void:
	## show "MISS" floating text.
	var label = Label.new()
	label.text = "MISS"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-15, -40)
	add_child(label)
	
	var tween = create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 40, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)



func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	pass  # damage numbers are triggered from the main script, not here


func _on_defeated() -> void:
	## fade out and sink when defeated.
	var tween = create_tween().set_parallel()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "position:y", sprite.position.y + 20, 0.8).set_ease(Tween.EASE_IN)


func _on_status_applied(effect_name: String) -> void:
	match effect_name:
		"POISON":
			sprite.modulate = Color(0.7, 1.0, 0.7)  # Greenish tint
		"STUN":
			sprite.modulate = Color(0.8, 0.8, 0.3)  # Yellowish tint


func _on_status_removed(effect_name: String) -> void:
	# reset to normal color if no other status effects
	if combatant.status_effects.is_empty():
		sprite.modulate = Color(1, 1, 1)
