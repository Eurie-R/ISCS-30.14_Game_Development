extends CharacterBody2D
@onready var animated_sprite = $"Agent Animator/AnimatedSprite2D"

#Reference Video: https://www.youtube.com/watch?v=oED12Mo2018

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

func _physics_process(delta: float) -> void:
	
	#Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	#Movement
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = (direction < 0) 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	#Animation
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jumping")
		else:
			animated_sprite.play("fall")
	else:
		if direction != 0:
			animated_sprite.play("walking")
		else:
			animated_sprite.play("idle")
	
	move_and_slide()
