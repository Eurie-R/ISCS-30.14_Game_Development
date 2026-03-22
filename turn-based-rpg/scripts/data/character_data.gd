class_name CharacterData
extends Resource

## Defines the base stats and moves for a character (player or enemy).

@export var character_name: String = ""
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 10
@export var is_player: bool = true
@export var sprite: Texture2D                # Character portrait or battle sprite
@export var moves: Array[MoveData] = []      # List of moves this character knows
