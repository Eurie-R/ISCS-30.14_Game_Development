extends Node

##loads data, wires up UI, and starts the battle.

#preload
var kael_data: CharacterData = preload("res://resources/characters/kael.tres")
var lyra_data: CharacterData = preload("res://resources/characters/lyra.tres")
var shadow_wolf_data: CharacterData = preload("res://resources/characters/shadow_wolf.tres")
var dark_knight_data: CharacterData = preload("res://resources/characters/dark_knight.tres")

var health_potion: ItemData = preload("res://resources/items/health_potion.tres")
var mana_potion: ItemData = preload("res://resources/items/mana_potion.tres")
var revival_herb: ItemData = preload("res://resources/items/revival_herb.tres")

var battle_scene_packed: PackedScene = preload("res://scenes/battle/battle_scene.tscn")
var character_displays: Dictionary = {}


var battle_scene: Node = null
var battle_manager: BattleManager = null
var battle_log: BattleLog = null
var command_menu: CommandMenu = null
var target_selector: TargetSelector = null
var battle_hud: BattleHUD = null

## tracks the current character being controlled and their pending action
var current_combatant: Combatant = null
var pending_move: MoveData = null
var pending_action_type: Action.ActionType = Action.ActionType.MOVE
var pending_item: ItemData = null

## item inventory for the battle
var inventory: Dictionary = {}


func _ready() -> void:
	# instance the battle scene
	battle_scene = battle_scene_packed.instantiate()
	add_child(battle_scene)
	
	#find all nodes
	battle_manager = battle_scene.get_node("BattleManager")
	
	var ui = battle_scene.get_node("BattleUI")
	var main_layout = ui.get_node("MainLayout")
	var bottom_section = main_layout.get_node("BottomSection")
	var bottom_layout = bottom_section.get_node("BottomLayout")
	
	battle_log = main_layout.get_node("LogPanel/LogScroll/BattleLog")
	command_menu = bottom_layout.get_node("CommandMenu")
	target_selector = bottom_layout.get_node("TargetSelector")
	battle_hud = ui.get_node("BattleHUD")
	
	#set the HUD's container references
	battle_hud.player_container = bottom_layout.get_node("PlayerStatus")
	battle_hud.enemy_container = main_layout.get_node("TopSection/EnemyStatus")
	
	
	
	#connect battlemanager signals
	battle_manager.action_executed.connect(_on_action_executed)
	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.player_input_requested.connect(_on_player_input_requested)
	
	# connect command menu signals
	command_menu.attack_selected.connect(_on_attack_selected)
	command_menu.magic_selected.connect(_on_magic_selected)
	command_menu.defend_selected.connect(_on_defend_selected)
	command_menu.item_selected.connect(_on_item_selected)
	command_menu.charge_selected.connect(_on_charge_selected)
	command_menu.move_selected.connect(_on_move_selected)
	
	#connect tarrgetselector signals
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.cancelled.connect(_on_target_cancelled)
	
	#create inventory
	inventory = {
		health_potion: 3,
		mana_potion: 2,
		revival_herb: 1
	}
	
	#setup combatants
	var players: Array[CharacterData] = [kael_data, lyra_data]
	var enemies: Array[CharacterData] = [shadow_wolf_data, dark_knight_data]
	
	battle_manager.setup_battle(players, enemies, inventory)
	
	# set up HUD after battle manager creates combatants
	battle_hud.setup_hud(battle_manager.player_party, battle_manager.enemy_party)
	_spawn_character_displays()
	battle_manager.start_battle()



#battle manager signal handlers

func _on_action_executed(message: String) -> void:
	if message != "":
		battle_log.add_message(message)
		print(message)
	
	# parse the message for visual cues
	if "damage" in message.to_lower() and "poison" not in message.to_lower():
		# find which combatant was damaged by checking names
		for combatant in character_displays.keys():
			var name = combatant.get_character_name()
			if name in message and ("on %s" % name) in message:
				var display = get_display(combatant)
				if display:
					display.play_damage_flash()
					# extract damage number
					var damage_num = _extract_number(message)
					if damage_num > 0:
						var is_crit = "Critical" in message or "critical" in message
						display.show_damage_number(damage_num, is_crit)
	
	if "missed" in message.to_lower():
		for combatant in character_displays.keys():
			if combatant.get_character_name() in message and ("on %s" % combatant.get_character_name()) in message:
				var display = get_display(combatant)
				if display:
					display.show_miss_text()
	
	if "restored" in message.to_lower() and "hp" in message.to_lower():
		for combatant in character_displays.keys():
			if ("on %s" % combatant.get_character_name()) in message:
				var display = get_display(combatant)
				if display:
					display.play_heal_effect()
					var heal_num = _extract_number(message)
					if heal_num > 0:
						display.show_damage_number(heal_num, false, true)
	
	if "charging" in message.to_lower():
		for combatant in character_displays.keys():
			if combatant.get_character_name() in message:
				var display = get_display(combatant)
				if display:
					display.play_charge_glow()
	
	if "defending" in message.to_lower():
		for combatant in character_displays.keys():
			if combatant.get_character_name() in message:
				var display = get_display(combatant)
				if display:
					display.play_defend_effect()
	
	if "used" in message.to_lower() and "damage" in message.to_lower():
		# find the attacker and play their attack animation
		for combatant in character_displays.keys():
			var name = combatant.get_character_name()
			if message.begins_with(name) or message.begins_with("CHARGED! %s" % name):
				var display = get_display(combatant)
				if display:
					display.play_attack_animation()
	
	if "defeated" in message.to_lower():
		# defeated animation is handled by the signal in CharacterDisplay already
		pass


func _extract_number(text: String) -> int:
	## pull the last number from a message like "Kael used Slash on Shadow Wolf! 45 damage!"
	var regex = RegEx.new()
	regex.compile("(\\d+)\\s*(damage|HP|MP)")
	var result = regex.search(text)
	if result:
		return int(result.get_string(1))
	
	# fallback: find any number
	regex.compile("(\\d+)")
	var results = regex.search_all(text)
	if not results.is_empty():
		return int(results[results.size() - 1].get_string(1))
	
	return 0


func _on_battle_won() -> void:
	command_menu.hide_menu()
	target_selector.hide_selector()


func _on_battle_lost() -> void:
	command_menu.hide_menu()
	target_selector.hide_selector()


func _on_player_input_requested(combatant: Combatant) -> void:
	## the battle manager is asking us to provide input for this character.
	current_combatant = combatant
	pending_move = null
	pending_item = null
	target_selector.hide_selector()
	command_menu.show_commands(combatant)



# command Menu Signal Handlers

func _on_attack_selected() -> void:
	# The command menu will show the attack sub-menu automatically
	# (it calls _show_attack_submenu internally and then emits move_selected)
	pass


func _on_magic_selected() -> void:
	#command menu shows magic sub-menu, then emits move_selected
	pass


func _on_move_selected(move: MoveData) -> void:
	##player picked a specific move. Now we need a target.
	pending_move = move
	pending_action_type = Action.ActionType.MOVE
	command_menu.hide_menu()
	
	# show appropriate targets
	match move.target_type:
		MoveData.TargetType.SINGLE_ENEMY:
			var enemies = battle_manager.get_alive_enemies()
			target_selector.show_targets(enemies, "Attack which enemy?")
		MoveData.TargetType.ALL_ENEMIES:
			# no target selection needed, auto-submit
			_submit_action_all_enemies()
		MoveData.TargetType.SINGLE_ALLY:
			var allies = battle_manager.get_alive_players()
			target_selector.show_targets(allies, "Heal which ally?")
		MoveData.TargetType.SELF:
			# no target selection needed, auto-submit targeting self
			_submit_action_self()


func _on_defend_selected() -> void:
	## defend doesn't need a target, submit immediately.
	command_menu.hide_menu()
	target_selector.hide_selector()
	
	var action = Action.new()
	action.actor = current_combatant
	action.action_type = Action.ActionType.DEFEND
	action.targets = [current_combatant]
	
	#find the defend move data for priority sorting
	for move in current_combatant.base_data.moves:
		if move.move_type == MoveData.MoveType.DEFEND:
			action.move = move
			break
	
	battle_manager.submit_player_action(action)


func _on_item_selected() -> void:
	##show available items as targets.
	command_menu.hide_menu()
	_show_item_selection()


func _on_charge_selected() -> void:
	##charge doesn't need a target, submit immediately.
	command_menu.hide_menu()
	target_selector.hide_selector()
	
	var action = Action.new()
	action.actor = current_combatant
	action.action_type = Action.ActionType.CHARGE
	action.targets = [current_combatant]
	
	#find the charge move data for priority sorting
	for move in current_combatant.base_data.moves:
		if move.move_type == MoveData.MoveType.CHARGE:
			action.move = move
			break
	
	battle_manager.submit_player_action(action)


# target selection handlers
func _on_target_selected(target: Combatant) -> void:
	##a target was picked. build and submit the action.
	target_selector.hide_selector()
	
	if pending_action_type == Action.ActionType.ITEM:
		_submit_item_action(target)
		return
	
	var action = Action.new()
	action.actor = current_combatant
	action.action_type = Action.ActionType.MOVE
	action.move = pending_move
	action.targets = [target]
	
	battle_manager.submit_player_action(action)


func _on_target_cancelled() -> void:
	##player hit Cancel -> go back to command menu.
	target_selector.hide_selector()
	command_menu.show_commands(current_combatant)



# item system

func _show_item_selection() -> void:
	## show available items using the target selector's UI.
	## we'll repurpose target selector to show items first, then target.
	target_selector._clear_children()
	
	var title = Label.new()
	title.text = "Use which item?"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	target_selector.add_child(title)
	
	var has_items = false
	for item in inventory.keys():
		var qty = inventory[item]
		if qty > 0:
			has_items = true
			var item_data = item as ItemData
			var btn = Button.new()
			btn.text = "%s (x%d)" % [item_data.item_name, qty]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(220, 36)
			
			#style
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.2, 0.1, 0.9)
			style.border_color = Color(0.4, 0.5, 0.3)
			style.set_border_width_all(1)
			style.set_corner_radius_all(4)
			style.set_content_margin_all(8)
			btn.add_theme_stylebox_override("normal", style)
			
			var hover_style = style.duplicate()
			hover_style.bg_color = Color(0.25, 0.3, 0.15, 0.95)
			btn.add_theme_stylebox_override("hover", hover_style)
			
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_color_override("font_color", Color(0.9, 0.95, 0.8))
			
			#capture item in closure
			var captured_item = item_data
			btn.pressed.connect(func(): _on_item_chosen(captured_item))
			target_selector.add_child(btn)
	
	if not has_items:
		var empty_label = Label.new()
		empty_label.text = "No items left!"
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
		target_selector.add_child(empty_label)
	
	#back button
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(220, 36)
	back_btn.add_theme_font_size_override("font_size", 14)
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	back_style.border_color = Color(0.4, 0.4, 0.6)
	back_style.set_border_width_all(1)
	back_style.set_corner_radius_all(4)
	back_style.set_content_margin_all(8)
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.pressed.connect(func(): _on_target_cancelled())
	target_selector.add_child(back_btn)
	
	target_selector.visible = true


func _on_item_chosen(item: ItemData) -> void:
	##an item was picked now select who to use it on.
	pending_item = item
	pending_action_type = Action.ActionType.ITEM
	
	match item.effect_type:
		ItemData.ItemEffect.HEAL_HP, ItemData.ItemEffect.HEAL_MP, ItemData.ItemEffect.BUFF_ATK, ItemData.ItemEffect.BUFF_DEF:
			var allies = battle_manager.get_alive_players()
			target_selector.show_targets(allies, "Use %s on who?" % item.item_name)
		ItemData.ItemEffect.REVIVE:
			# show only defeated allies
			var dead_allies = battle_manager.player_party.filter(func(c): return not c.is_alive())
			if dead_allies.is_empty():
				battle_log.add_message("No fallen allies to revive!")
				_on_target_cancelled()
			else:
				target_selector.show_targets(dead_allies, "Revive which ally?")


func _submit_item_action(target: Combatant) -> void:
	var action = Action.new()
	action.actor = current_combatant
	action.action_type = Action.ActionType.ITEM
	action.item = pending_item
	action.targets = [target]
	
	battle_manager.submit_player_action(action)



# auto-submit Helpers (AoE / Self targets)

func _submit_action_all_enemies() -> void:
	target_selector.hide_selector()
	
	var action = Action.new()
	action.actor = current_combatant
	action.action_type = Action.ActionType.MOVE
	action.move = pending_move
	action.targets = battle_manager.get_alive_enemies()
	
	battle_manager.submit_player_action(action)


func _submit_action_self() -> void:
	target_selector.hide_selector()
	
	var action = Action.new()
	action.actor = current_combatant
	action.action_type = Action.ActionType.MOVE
	action.move = pending_move
	action.targets = [current_combatant]
	
	battle_manager.submit_player_action(action)
	

#char display visuals
func _spawn_character_displays() -> void:
	print("=== SPAWNING CHARACTER DISPLAYS ===")
	
	var display_container = battle_scene.get_node_or_null("CharacterDisplays")
	var player_positions = battle_scene.get_node_or_null("PlayerPositions")
	var enemy_positions = battle_scene.get_node_or_null("EnemyPositions")
	
	print("display_container: ", display_container)
	print("player_positions: ", player_positions)
	print("enemy_positions: ", enemy_positions)
	
	if display_container == null:
		push_error("CharacterDisplays node not found!")
		return
	if player_positions == null:
		push_error("PlayerPositions node not found!")
		return
	if enemy_positions == null:
		push_error("EnemyPositions node not found!")
		return
	
	print("Player party size: ", battle_manager.player_party.size())
	print("Enemy party size: ", battle_manager.enemy_party.size())
	
	# spawn player displays
	for i in range(battle_manager.player_party.size()):
		var combatant = battle_manager.player_party[i]
		var display = CharacterDisplay.new()
		var marker = player_positions.get_child(mini(i, player_positions.get_child_count() - 1))
		display.position = marker.position
		display_container.add_child(display)
		display.setup(combatant, false)
		character_displays[combatant] = display
		print("Spawned player: %s at position %s" % [combatant.get_character_name(), str(display.position)])
	
	# Spawn enemy displays
	for i in range(battle_manager.enemy_party.size()):
		var combatant = battle_manager.enemy_party[i]
		var display = CharacterDisplay.new()
		var marker = enemy_positions.get_child(mini(i, enemy_positions.get_child_count() - 1))
		display.position = marker.position
		display_container.add_child(display)
		display.setup(combatant, true)
		character_displays[combatant] = display
		print("Spawned enemy: %s at position %s" % [combatant.get_character_name(), str(display.position)])
	
	print("Total displays: ", character_displays.size())
	print("=== DONE ===")


func get_display(combatant: Combatant) -> CharacterDisplay:
	if character_displays.has(combatant):
		return character_displays[combatant]
	return null
