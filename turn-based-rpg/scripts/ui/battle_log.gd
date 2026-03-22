class_name BattleLog
extends VBoxContainer

## scrolling battle log that displays combat messages.

const MAX_MESSAGES: int = 50

@onready var scroll_container: ScrollContainer = get_parent() as ScrollContainer

func add_message(text: String) -> void:
	if text.strip_edges() == "":
		return
	
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	
	# Color code different message types
	if "VICTORY" in text:
		label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold
	elif "DEFEAT" in text:
		label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))  # Red
	elif "Critical hit" in text:
		label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))  # Orange
	elif "missed" in text:
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))  # Gray
	elif "defeated" in text:
		label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))  # Light red
	elif "Restored" in text or "healed" in text.to_lower():
		label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))  # Green
	elif "charging" in text.to_lower():
		label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))  # Blue
	elif "defending" in text.to_lower():
		label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))  # Light blue
	elif "Turn" in text and "---" in text:
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))  # Yellow
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White
	
	add_child(label)
	
	# remove old messages if too many
	while get_child_count() > MAX_MESSAGES:
		var old = get_child(0)
		remove_child(old)
		old.queue_free()
	
	# auto-scroll to bottom on next frame
	if scroll_container:
		await get_tree().process_frame
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)


func clear_log() -> void:
	for child in get_children():
		child.queue_free()
