class_name BattleManager
extends Node

## core battle handler. controls the entire turn-based battle loop.
## simultaneous turn-based system:
## 1 player picks actions for all characters
## 2 enemy AI picks actions for all enemies
## 3 all actions are sorted by priority/speed and resolved in order
## 4 check for win/loss
## 5 repeat

#signals
signal battle_started()
signal turn_started(turn_number: int)
signal player_input_requested(combatant: Combatant)
signal player_input_completed()
signal enemy_input_completed()
signal resolution_started()
signal action_executed(message: String)
signal battle_won()
signal battle_lost()
signal battle_ended()

# battlestate
enum BattleState {
	INACTIVE,
	INTRO,
	PLAYER_INPUT,
	ENEMY_INPUT,
	RESOLUTION,
	CHECK_END,
	VICTORY,
	DEFEAT
}

var current_state: BattleState = BattleState.INACTIVE


var player_party: Array[Combatant] = []
var enemy_party: Array[Combatant] = []

#turn data
var turn_actions: Array[Action] = []
var current_turn: int = 0

## which player character is currently selecting their action.
var current_input_index: int = 0

## enemy AI handler
var enemy_ai: EnemyAI = EnemyAI.new()

## shared inventory of items. dictionary of {ItemData: quantity}.
var inventory: Dictionary = {}



#setup
func setup_battle(players: Array[CharacterData], enemies: Array[CharacterData], items: Dictionary = {}) -> void:
	## call before starting the battle. creates combatant nodes for each character.
	
	# create player combatants
	for data in players:
		var combatant = Combatant.new()
		combatant.initialize(data)
		add_child(combatant)
		player_party.append(combatant)
	
	# create enemy combatants
	for data in enemies:
		var combatant = Combatant.new()
		combatant.initialize(data)
		add_child(combatant)
		enemy_party.append(combatant)
	
	# set up inventory
	inventory = items.duplicate()
	
	current_state = BattleState.INACTIVE


func start_battle() -> void:
	## begin the battle sequence.
	current_state = BattleState.INTRO
	current_turn = 0
	battle_started.emit()
	action_executed.emit("Battle Start!")
	
	# brief pause for intro, then start first turn
	await get_tree().create_timer(1.0).timeout
	_start_new_turn()


func _start_new_turn() -> void:
	current_turn += 1
	turn_actions.clear()
	turn_started.emit(current_turn)
	action_executed.emit("--- Turn %d ---" % current_turn)
	
	# clear defend flags from last turn
	for c in player_party:
		if c.is_alive():
			c.clear_turn_flags()
	for c in enemy_party:
		if c.is_alive():
			c.clear_turn_flags()
	
	# check for stun — stunned characters skip their turn
	for c in player_party:
		if c.is_alive() and c.is_stunned():
			action_executed.emit("%s is stunned and can't move!" % c.get_character_name())
	
	for c in enemy_party:
		if c.is_alive() and c.is_stunned():
			action_executed.emit("%s is stunned and can't move!" % c.get_character_name())
	
	# move to player input
	current_state = BattleState.PLAYER_INPUT
	current_input_index = 0
	_request_next_player_input()


func _request_next_player_input() -> void:
	## find the next alive, non-stunned player character and request their input.
	while current_input_index < player_party.size():
		var combatant = player_party[current_input_index]
		if combatant.is_alive() and not combatant.is_stunned():
			player_input_requested.emit(combatant)
			return  # wait for UI to call submit_player_action()
		else:
			current_input_index += 1
	
	# all players have submitted actions
	player_input_completed.emit()
	_do_enemy_input()


func submit_player_action(action: Action) -> void:
	## called by the UI when the player has chosen an action for the current character.
	turn_actions.append(action)
	current_input_index += 1
	_request_next_player_input()


func _do_enemy_input() -> void:
	## AI selects actions for all alive, non-stunned enemies.
	current_state = BattleState.ENEMY_INPUT
	
	for enemy in enemy_party:
		if enemy.is_alive() and not enemy.is_stunned():
			#var action = _simple_enemy_ai(enemy)
			var action = enemy_ai.choose_action(enemy, player_party, enemy_party)
			turn_actions.append(action)
	
	enemy_input_completed.emit()
	
	# small delay before resolution for feel
	await get_tree().create_timer(0.5).timeout
	_resolve_turn()



func _simple_enemy_ai(enemy: Combatant) -> Action:
	## basic enemy AI: randomly pick a move and a target.
	var action = Action.new()
	action.actor = enemy
	
	# get available moves (ones the enemy can afford)
	var available_moves: Array[MoveData] = []
	for move in enemy.base_data.moves:
		if enemy.can_afford_move(move):
			available_moves.append(move)
	
	# if no moves are affordable, just do a basic attack with the first move
	if available_moves.is_empty():
		available_moves.append(enemy.base_data.moves[0])
	
	# random move selection (RNG requirement)
	var chosen_move: MoveData = available_moves[randi() % available_moves.size()]
	
	action.move = chosen_move
	
	# determine action type
	match chosen_move.move_type:
		MoveData.MoveType.DEFEND:
			action.action_type = Action.ActionType.DEFEND
			action.targets = [enemy]
		MoveData.MoveType.CHARGE:
			action.action_type = Action.ActionType.CHARGE
			action.targets = [enemy]
		_:
			action.action_type = Action.ActionType.MOVE
			# pick target based on move's target type
			match chosen_move.target_type:
				MoveData.TargetType.SINGLE_ENEMY:
					# enemy targets a player — prefer lowest HP
					var alive_players = player_party.filter(func(c): return c.is_alive())
					if alive_players.size() > 0:
						alive_players.sort_custom(func(a, b): return a.current_hp < b.current_hp)
						# 50% chance to target lowest HP, 50% random (adds unpredictability)
						if randf() < 0.5:
							action.targets = [alive_players[0]]
						else:
							action.targets = [alive_players[randi() % alive_players.size()]]
				MoveData.TargetType.ALL_ENEMIES:
					# "ALL_ENEMIES" from enemy perspective = all players
					action.targets = player_party.filter(func(c): return c.is_alive())
				MoveData.TargetType.SINGLE_ALLY:
					# enemy healing another enemy
					var alive_enemies = enemy_party.filter(func(c): return c.is_alive())
					action.targets = [alive_enemies[randi() % alive_enemies.size()]]
				MoveData.TargetType.SELF:
					action.targets = [enemy]
	
	return action


#turn resolution
func _resolve_turn() -> void:
	## sort all actions and execute them one by one.
	current_state = BattleState.RESOLUTION
	resolution_started.emit()
	
	# sort by: priority (descending) → speed (descending) → random tiebreak
	turn_actions.sort_custom(_compare_actions)
	
	# execute each action
	for action in turn_actions:
		# skip dead actors (they may have been killed earlier this turn)
		if not action.actor.is_alive():
			continue
		
		await _execute_action(action)
		
		# small delay between actions for readability
		await get_tree().create_timer(0.8).timeout
	
	#end of turn, process status effects
	action_executed.emit("")  # Blank line for readability
	
	var all_combatants: Array = []
	all_combatants.append_array(player_party)
	all_combatants.append_array(enemy_party)
	
	for combatant in all_combatants:
		if combatant.is_alive():
			var messages = combatant.process_status_effects()
			for msg in messages:
				action_executed.emit(msg)
				await get_tree().create_timer(0.5).timeout
	
	# check for end of battle
	_check_end_state()


func _compare_actions(a: Action, b: Action) -> bool:
	## sorting function. Returns true if action 'a' should go before 'b'.
	var priority_a = a.get_priority()
	var priority_b = b.get_priority()
	
	if priority_a != priority_b:
		return priority_a > priority_b  # Higher priority goes first
	
	var speed_a = a.get_speed()
	var speed_b = b.get_speed()
	
	if speed_a != speed_b:
		return speed_a > speed_b  # Higher speed goes first
	
	# random tiebreak
	return randf() > 0.5


func _execute_action(action: Action) -> void:
	## execute a single action.
	var actor = action.actor
	
	match action.action_type:
		Action.ActionType.DEFEND:
			actor.set_defending()
			action_executed.emit("%s is defending!" % actor.get_character_name())
		
		Action.ActionType.CHARGE:
			actor.set_charged()
			action_executed.emit("%s is charging up power!" % actor.get_character_name())
		
		Action.ActionType.ITEM:
			await _execute_item(action)
		
		Action.ActionType.MOVE:
			await _execute_move(action)


func _execute_move(action: Action) -> void:
	## execute an attack, magic, or heal move.
	var actor = action.actor
	var move = action.move
	
	# spend MP
	if move.mp_cost > 0:
		actor.use_mp(move.mp_cost)
	
	match move.move_type:
		MoveData.MoveType.HEAL:
			# healing move
			for target in action.targets:
				if target.is_alive():
					var heal_amount = DamageCalc.calculate_heal(actor, move)
					var actual = target.heal_hp(heal_amount)
					action_executed.emit("%s used %s on %s! Restored %d HP!" % [
						actor.get_character_name(),
						move.move_name,
						target.get_character_name(),
						actual
					])
		
		MoveData.MoveType.PHYSICAL, MoveData.MoveType.MAGICAL:
			# damage move
			for target in action.targets:
				if target.is_alive():
					var result = DamageCalc.calculate_damage(actor, target, move)
					action_executed.emit(result.message)
					
					if not result.is_miss:
						target.take_damage(result.damage)
						
						# check for status effect application
						if move.status_effect != MoveData.StatusEffect.NONE:
							if DamageCalc.roll_status(move.status_chance):
								target.apply_status(move.status_effect)
								var effect_name = MoveData.StatusEffect.keys()[move.status_effect]
								action_executed.emit("%s is now affected by %s!" % [
									target.get_character_name(),
									effect_name
								])
						
						# check if target was defeated
						if not target.is_alive():
							action_executed.emit("%s was defeated!" % target.get_character_name())
		
		MoveData.MoveType.DEFEND:
			actor.set_defending()
			action_executed.emit("%s is defending!" % actor.get_character_name())
		
		MoveData.MoveType.CHARGE:
			actor.set_charged()
			action_executed.emit("%s is charging up power!" % actor.get_character_name())
		
		_:
			# self-targeting buff/debuff moves (like Howl)
			if move.status_effect != MoveData.StatusEffect.NONE:
				for target in action.targets:
					if target.is_alive():
						if DamageCalc.roll_status(move.status_chance):
							target.apply_status(move.status_effect)
							var effect_name = MoveData.StatusEffect.keys()[move.status_effect]
							action_executed.emit("%s used %s! %s's %s changed!" % [
								actor.get_character_name(),
								move.move_name,
								target.get_character_name(),
								effect_name
							])


func _execute_item(action: Action) -> void:
	## use an item from inventory.
	var actor = action.actor
	var item = action.item as ItemData
	
	if item == null:
		return
	
	# check if we still have the item
	if not inventory.has(item) or inventory[item] <= 0:
		action_executed.emit("%s tried to use %s, but there are none left!" % [
			actor.get_character_name(), item.item_name
		])
		return
	
	# consume the item
	inventory[item] -= 1
	
	for target in action.targets:
		match item.effect_type:
			ItemData.ItemEffect.HEAL_HP:
				var actual = target.heal_hp(item.potency)
				action_executed.emit("%s used %s on %s! Restored %d HP!" % [
					actor.get_character_name(), item.item_name,
					target.get_character_name(), actual
				])
			
			ItemData.ItemEffect.HEAL_MP:
				var actual = target.heal_mp(item.potency)
				action_executed.emit("%s used %s on %s! Restored %d MP!" % [
					actor.get_character_name(), item.item_name,
					target.get_character_name(), actual
				])
			
			ItemData.ItemEffect.REVIVE:
				if not target.is_alive():
					var revive_hp = int(target.base_data.max_hp * item.potency / 100.0)
					target.current_hp = revive_hp
					target.hp_changed.emit(target.current_hp, target.base_data.max_hp)
					action_executed.emit("%s used %s! %s was revived with %d HP!" % [
						actor.get_character_name(), item.item_name,
						target.get_character_name(), revive_hp
					])


#win/loss check

func _check_end_state() -> void:
	current_state = BattleState.CHECK_END
	
	var all_enemies_dead = enemy_party.all(func(c): return not c.is_alive())
	var all_players_dead = player_party.all(func(c): return not c.is_alive())
	
	if all_enemies_dead:
		current_state = BattleState.VICTORY
		action_executed.emit("")
		action_executed.emit("══════ VICTORY! ══════")
		battle_won.emit()
		battle_ended.emit()
	elif all_players_dead:
		current_state = BattleState.DEFEAT
		action_executed.emit("")
		action_executed.emit("══════ DEFEAT... ══════")
		battle_lost.emit()
		battle_ended.emit()
	else:
		# Battle continues — start next turn
		await get_tree().create_timer(0.5).timeout
		_start_new_turn()


#helper functions
func get_alive_players() -> Array:
	return player_party.filter(func(c): return c.is_alive())

func get_alive_enemies() -> Array:
	return enemy_party.filter(func(c): return c.is_alive())

func get_current_input_combatant() -> Combatant:
	if current_input_index < player_party.size():
		return player_party[current_input_index]
	return null
