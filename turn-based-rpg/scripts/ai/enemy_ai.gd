class_name EnemyAI
extends RefCounted

## dedicated enemy AI with smarter decision-making.
## considers HP thresholds, buff opportunities, and target priority.

## choose an action for a single enemy combatant.
func choose_action(
	enemy: Combatant,
	player_party: Array,
	enemy_party: Array
) -> Action:
	var action = Action.new()
	action.actor = enemy
	
	var alive_players = player_party.filter(func(c): return c.is_alive())
	var alive_enemies = enemy_party.filter(func(c): return c.is_alive())
	
	if alive_players.is_empty():
		return _make_defend_action(enemy)
	
	var available_moves: Array[MoveData] = []
	for move in enemy.base_data.moves:
		if enemy.can_afford_move(move):
			available_moves.append(move)
	
	if available_moves.is_empty():
		return _make_defend_action(enemy)
	

	#decision logic
	#1. if HP is low (below 30%), prefer defensive moves
	var hp_ratio = float(enemy.current_hp) / float(enemy.base_data.max_hp)
	if hp_ratio < 0.3:
		var defend_moves = available_moves.filter(func(m):
			return m.move_type == MoveData.MoveType.DEFEND
		)
		if not defend_moves.is_empty() and randf() < 0.6:
			return _make_defend_action(enemy)
	
	#2. if not buffed yet, consider buff moves
	var buff_moves = available_moves.filter(func(m):
		return m.target_type == MoveData.TargetType.SELF and m.status_effect == MoveData.StatusEffect.BUFF_ATK
	)
	if not buff_moves.is_empty() and not enemy.has_status("BUFF_ATK"):
		# 40% chance to use a buff if not already buffed
		if randf() < 0.4:
			var buff_move = buff_moves[0]
			action.action_type = Action.ActionType.MOVE
			action.move = buff_move
			action.targets = [enemy]
			return action
	
	#3. prefer AoE if multiple players alive
	if alive_players.size() >= 2:
		var aoe_moves = available_moves.filter(func(m):
			return m.target_type == MoveData.TargetType.ALL_ENEMIES
		)
		if not aoe_moves.is_empty() and randf() < 0.35:
			var aoe_move = aoe_moves[randi() % aoe_moves.size()]
			action.action_type = Action.ActionType.MOVE
			action.move = aoe_move
			action.targets = alive_players.duplicate()
			return action
	
	#4. normal attack, pick from offensive moves
	var attack_moves = available_moves.filter(func(m):
		return m.move_type == MoveData.MoveType.PHYSICAL or m.move_type == MoveData.MoveType.MAGICAL
	)
	
	if attack_moves.is_empty():
		attack_moves = available_moves  # Fallback
	
	# weighted random: higher power moves have slightly more weight
	var chosen_move = _weighted_pick(attack_moves)
	
	action.action_type = Action.ActionType.MOVE
	action.move = chosen_move
	
	# target selection
	match chosen_move.target_type:
		MoveData.TargetType.SINGLE_ENEMY:
			action.targets = [_pick_target(alive_players)]
		MoveData.TargetType.ALL_ENEMIES:
			action.targets = alive_players.duplicate()
		MoveData.TargetType.SELF:
			action.targets = [enemy]
		MoveData.TargetType.SINGLE_ALLY:
			action.targets = [alive_enemies[randi() % alive_enemies.size()]]
	
	return action


func _make_defend_action(enemy: Combatant) -> Action:
	var action = Action.new()
	action.actor = enemy
	action.action_type = Action.ActionType.DEFEND
	action.targets = [enemy]
	return action


func _pick_target(alive_players: Array) -> Combatant:
	## Smart targeting:
	## 50% chance to target the lowest HP player
	## 30% chance to target the highest attack
	## 20% purely random
	var roll = randf()
	
	if roll < 0.5:
		#target lowest hp
		var sorted = alive_players.duplicate()
		sorted.sort_custom(func(a, b): return a.current_hp < b.current_hp)
		return sorted[0]
	elif roll < 0.8:
		#target highest attack
		var sorted = alive_players.duplicate()
		sorted.sort_custom(func(a, b): return a.get_attack() > b.get_attack())
		return sorted[0]
	else:
		# random
		return alive_players[randi() % alive_players.size()]


func _weighted_pick(moves: Array) -> MoveData:
	## weighted random, moves with higher power have more weight.
	var total_weight: float = 0.0
	for move in moves:
		total_weight += maxf(1.0, move.power)
	
	var roll = randf() * total_weight
	var cumulative: float = 0.0
	for move in moves:
		cumulative += maxf(1.0, move.power)
		if roll <= cumulative:
			return move
	
	return moves[moves.size() - 1]
