class_name MoveData
extends Resource

## Defines a single move/command that a character can use.

enum MoveType {
	PHYSICAL,   # Uses Attack stat
	MAGICAL,    # Uses Attack stat but could use a separate Magic stat later
	HEAL,       # Restores HP
	DEFEND,     # Reduces incoming damage
	CHARGE,     # Skips turn to power up next attack
	ITEM        # Uses an item
}

enum TargetType {
	SINGLE_ENEMY,   # Pick one enemy
	ALL_ENEMIES,    # Hits every enemy
	SINGLE_ALLY,    # Pick one ally (for heals)
	SELF            # Targets self only
}

enum StatusEffect {
	NONE,
	POISON,      # Damage over time
	STUN,        # Skip next turn
	BUFF_ATK,    # Raise attack
	DEBUFF_DEF   # Lower defense
}

@export var move_name: String = ""
@export var description: String = ""
@export var move_type: MoveType = MoveType.PHYSICAL
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var power: int = 10
@export var mp_cost: int = 0
@export var priority: int = 0         # Higher = goes first (like Quick Attack in Pokémon)
@export var accuracy: int = 100       # 0 to 100, chance to hit
@export var status_effect: StatusEffect = StatusEffect.NONE
@export var status_chance: int = 0    # 0 to 100, chance to apply the status
