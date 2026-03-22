class_name Combatant
extends Node

## Runtime state for one character during battle.
## Created from a CharacterData resource when the battle starts.

# ─── Signals ───
signal hp_changed(new_hp: int, max_hp: int)
signal mp_changed(new_mp: int, max_mp: int)
signal defeated()
signal status_applied(effect_name: String)
signal status_removed(effect_name: String)
signal action_performed(message: String)

# ─── Base Data ───
## The CharacterData resource this combatant was created from.
var base_data: CharacterData = null


var current_hp: int = 0
var current_mp: int = 0

var is_defending: bool = false

## if combatant used Charge last turn (next attack deals 2x).
var is_charged: bool = false

## status effects
## example: {"POISON": 3, "BUFF_ATK": 2}
var status_effects: Dictionary = {}


## temporary stat modifiers from buffs/debuffs.
var attack_modifier: int = 0
var defense_modifier: int = 0


#initialization

## call this to set up the combatant from a CharacterData resource.
func initialize(data: CharacterData) -> void:
	base_data = data
	current_hp = data.max_hp
	current_mp = data.max_mp
	name = data.character_name  # sets the Node name for easy identification
	is_defending = false
	is_charged = false
	status_effects.clear()
	attack_modifier = 0
	defense_modifier = 0



## return the effective stat after modifiers.

func get_attack() -> int:
	return maxi(1, base_data.attack + attack_modifier)

func get_defense() -> int:
	return maxi(1, base_data.defense + defense_modifier)

func get_speed() -> int:
	return base_data.speed

func get_character_name() -> String:
	return base_data.character_name



func take_damage(amount: int) -> int:
	## apply damage. if defending, halve it. returns actual damage dealt.
	var actual = amount
	if is_defending:
		actual = int(amount * 0.5)
	
	actual = maxi(1, actual)  # always deal at least 1 damage
	current_hp = maxi(0, current_hp - actual)
	hp_changed.emit(current_hp, base_data.max_hp)
	
	if current_hp <= 0:
		defeated.emit()
	
	return actual

func heal_hp(amount: int) -> int:
	## restore HP. Returns actual amount healed.
	var before = current_hp
	current_hp = mini(current_hp + amount, base_data.max_hp)
	var actual_heal = current_hp - before
	hp_changed.emit(current_hp, base_data.max_hp)
	return actual_heal



func use_mp(amount: int) -> bool:
	## spend MP. returns true if the character had enough.
	if current_mp >= amount:
		current_mp -= amount
		mp_changed.emit(current_mp, base_data.max_mp)
		return true
	return false

func heal_mp(amount: int) -> int:
	## restore MP. returns actual amount restored.
	var before = current_mp
	current_mp = mini(current_mp + amount, base_data.max_mp)
	var actual_heal = current_mp - before
	mp_changed.emit(current_mp, base_data.max_mp)
	return actual_heal



func apply_status(effect: MoveData.StatusEffect, duration: int = 3) -> void:
	## apply a status effect for a number of turns.
	var effect_name = MoveData.StatusEffect.keys()[effect]
	status_effects[effect_name] = duration
	
	# apply immediate stat changes for buffs/debuffs
	match effect:
		MoveData.StatusEffect.BUFF_ATK:
			attack_modifier += 5
		MoveData.StatusEffect.DEBUFF_DEF:
			defense_modifier -= 5
	
	status_applied.emit(effect_name)

func process_status_effects() -> Array[String]:
	## called at end of turn. ticks down durations, applies ongoing effects.
	## returns an array of messages for the battle log.
	var messages: Array[String] = []
	var to_remove: Array[String] = []
	
	for effect_name in status_effects.keys():
		match effect_name:
			"POISON":
				var poison_dmg = maxi(1, int(base_data.max_hp * 0.1))
				current_hp = maxi(0, current_hp - poison_dmg)
				hp_changed.emit(current_hp, base_data.max_hp)
				messages.append("%s took %d poison damage!" % [get_character_name(), poison_dmg])
				if current_hp <= 0:
					defeated.emit()
			"STUN":
				pass  # stun is checked at the start of the turn, not end
		
		# tick down duration
		status_effects[effect_name] -= 1
		if status_effects[effect_name] <= 0:
			to_remove.append(effect_name)
	
	# remove expired effects
	for effect_name in to_remove:
		_remove_status(effect_name)
		messages.append("%s is no longer affected by %s." % [get_character_name(), effect_name])
	
	return messages

func _remove_status(effect_name: String) -> void:
	## remove a status effect and revert its stat changes.
	match effect_name:
		"BUFF_ATK":
			attack_modifier -= 5
		"DEBUFF_DEF":
			defense_modifier += 5
	
	status_effects.erase(effect_name)
	status_removed.emit(effect_name)

func has_status(effect_name: String) -> bool:
	return status_effects.has(effect_name)


#turn manangement
func clear_turn_flags() -> void:
	## Called at the start of each new turn.
	is_defending = false

func set_defending() -> void:
	is_defending = true

func set_charged() -> void:
	is_charged = true

func consume_charge() -> bool:
	## If charged, consume it and return true.
	if is_charged:
		is_charged = false
		return true
	return false


#state checks
func is_alive() -> bool:
	return current_hp > 0

func is_stunned() -> bool:
	return has_status("STUN")

func can_afford_move(move: MoveData) -> bool:
	return current_mp >= move.mp_cost

func is_player() -> bool:
	return base_data.is_player
