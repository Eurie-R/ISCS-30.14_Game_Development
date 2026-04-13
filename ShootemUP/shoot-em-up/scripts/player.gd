extends CharacterBody2D


@export var speed = 300
const PROJECTILE = preload("uid://footd5uebrdw")

func _process(delta: float) -> void:
	var move = Input.get_vector("Left", "Right", "Up", "Down")
	if move:
		velocity = move * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	if Input.is_action_just_pressed("shoot"):
		var new_projectile = PROJECTILE.instantiate()
		new_projectile.global_position = global_position
		add_sibling(new_projectile)
	
	#Change value of x = 1152 y = 648 if youre going to change the border or world size 
	global_position.x = clamp(global_position.x, 0, 1152)
	global_position.y = clamp(global_position.y, 0, 648)
	
