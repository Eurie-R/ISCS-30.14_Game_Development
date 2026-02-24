extends Node2D
@onready var ENEMY = preload("uid://c011uryjydgu2")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_spawn_timer_timeout() -> void:
	var enemy = ENEMY.instantiate()
	enemy.position = Vector2(randf_range(1024,1024), randf_range(100,550))
	get_parent().add_child(enemy)
