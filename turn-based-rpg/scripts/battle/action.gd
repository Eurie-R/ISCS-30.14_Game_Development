class_name Action
extends RefCounted

## Stores one character's chosen action for the current turn.
## Created during input phase, consumed during resolution phase.

enum ActionType {
	MOVE,       
	ITEM,       
	DEFEND,     
	CHARGE     
}

var actor: Node = null   # the Combatant who performs this action
var action_type: ActionType = ActionType.MOVE
var move: MoveData = null  # which move to use (if action_type is MOVE)
var item: Resource = null   # which item to use (if action_type is ITEM)
var targets: Array = []  # array of Combatant nodes to target

## helper to get the priority for sorting.
## higher priority actions go first, then higher speed.
func get_priority() -> int:
	if move != null:
		return move.priority
	# Defend and Charge always have high priority (go first)
	if action_type == ActionType.DEFEND or action_type == ActionType.CHARGE:
		return 5
	# Items have medium priority
	if action_type == ActionType.ITEM:
		return 3
	return 0

## helper to get the actor's speed for tiebreaking.
func get_speed() -> int:
	if actor != null and actor.has_method("get_speed"):
		return actor.get_speed()
	return 0
