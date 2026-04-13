class_name DamageCalculator
extends Node

## handles all damage calculations and RNG for the battle system.
## registered as an Autoload so any script can access it via DamageCalc.


const CRIT_CHANCE: int = 10  # base 10% crit chance
const CRIT_MULTIPLIER: float = 1.5  # crits deal 1.5x damage
const CHARGE_MULTIPLIER: float = 2.0 # charged attacks deal 2x damage
const CHARGE_CRIT_BONUS: int = 20 # charged attacks get +20% crit chance
const DAMAGE_ROLL_MIN: float = 0.85 # min damage variance
const DAMAGE_ROLL_MAX: float = 1.15 # max damage variance


## result of a damage calculation, returned so the battle manager
## can display the right messages.
class DamageResult:
	var damage: int = 0
	var is_critical: bool = false
	var is_miss: bool = false
	var is_charged: bool = false
	var message: String = ""


## calculate damage for an attack move.
func calculate_damage(attacker: Combatant, defender: Combatant, move: MoveData) -> DamageResult:
	var result = DamageResult.new()
	
	#hit check
	var hit_roll = randi_range(1, 100)
	if hit_roll > move.accuracy:
		result.is_miss = true
		result.damage = 0
		result.message = "%s's %s missed!" % [attacker.get_character_name(), move.move_name]
		return result
	
	# base damage
	var atk = attacker.get_attack()
	var def = defender.get_defense()
	var base_damage: float = (atk * move.power) / maxf(1.0, def * 0.5)
	
	# damage variance (RNG)
	var roll = randf_range(DAMAGE_ROLL_MIN, DAMAGE_ROLL_MAX)
	base_damage *= roll
	
	# critical hit check (RNG)
	var crit_threshold = CRIT_CHANCE
	
	# check if attacker is charged (unique mechanic bonus)
	if attacker.consume_charge():
		result.is_charged = true
		base_damage *= CHARGE_MULTIPLIER
		crit_threshold += CHARGE_CRIT_BONUS
	
	var crit_roll = randi_range(1, 100)
	if crit_roll <= crit_threshold:
		result.is_critical = true
		base_damage *= CRIT_MULTIPLIER
	
	# final Damage 
	result.damage = maxi(1, int(base_damage))
	
	# build message
	result.message = "%s used %s on %s! " % [
		attacker.get_character_name(),
		move.move_name,
		defender.get_character_name()
	]
	if result.is_charged:
		result.message = "CHARGED! " + result.message
	if result.is_critical:
		result.message += "Critical hit! "
	result.message += "%d damage!" % result.damage
	
	return result


## calculate healing amount (simpler, no miss or crit).
func calculate_heal(healer: Combatant, move: MoveData) -> int:
	var base_heal: float = move.power
	# add a small variance to healing too
	var roll = randf_range(0.9, 1.1)
	return maxi(1, int(base_heal * roll))


## roll to see if a status effect applies.
func roll_status(chance: int) -> bool:
	return randi_range(1, 100) <= chance
