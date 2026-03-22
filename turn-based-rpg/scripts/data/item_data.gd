class_name ItemData
extends Resource

## Defines a usable item in the battle inventory.

enum ItemEffect {
	HEAL_HP,     # Restores hit points
	HEAL_MP,     # Restores magic points
	REVIVE,      # Brings back a defeated ally
	BUFF_ATK,    # Temporarily raises attack
	BUFF_DEF     # Temporarily raises defense
}

@export var item_name: String = ""
@export var description: String = ""
@export var effect_type: ItemEffect = ItemEffect.HEAL_HP
@export var potency: int = 50         # How strong the effect is (HP healed, etc.)
@export var icon: Texture2D           # Small icon for the UI (optional for now)
