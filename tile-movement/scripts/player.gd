extends CharacterBody2D



const speed = 100

var ground_layer: TileMapLayer
var ice_layer: TileMapLayer
var current_dir ="none"
var lastDirection : String = "down"
var idle_time = 0.0
var is_moving = false
var grid_pos : Vector2i 
var is_sliding := false
var slide_dir := Vector2.ZERO
var dir_slide := Vector2.ZERO
var is_slow := false

	
func _ready():
	ground_layer = get_parent().get_node("TileMap/Ground") 
	$AnimatedSprite2D.play("front_idle")

func _physics_process(_delta: float) -> void:
	
	var conveyor_force = check_conveyor()
	
	if get_last_slide_collision() != null:
		print("on Wall")
		
	if conveyor_force != Vector2.ZERO:
		velocity = conveyor_force * speed
		play_anim(0)
	else:
		if is_sliding:
			slide_step()
			var col = get_last_slide_collision()
			if col != null:
				stop_sliding()
		else:
			player_movement(_delta)
	
	move_and_slide()
	
	if is_on_wall():
		print("Wall Wall")
		stop_sliding()
	

func player_movement(_delta):
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		dir_slide = Vector2.RIGHT
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		dir_slide = Vector2.LEFT
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		dir_slide = Vector2.UP
		play_anim(1)
		velocity.x = 0
		velocity.y = -speed
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		dir_slide = Vector2.DOWN
		play_anim(1)
		velocity.x = 0
		velocity.y = speed
	else:
		play_anim(0)
		dir_slide = Vector2.ZERO
		velocity.x = 0
		velocity.y = 0
		
	#print("On ice:", is_ice_tile(global_position))
	print("On Sand:", get_speed_modifier())
	#Enter Ice
	if is_ice_tile(global_position) and not is_sliding:
		is_sliding = true
		slide_dir = dir_slide
		
	if is_slow:
		velocity *= get_speed_modifier()
		
	
func play_anim(movement):
	var dir = current_dir
	var anim = $AnimatedSprite2D
	
	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
	elif dir == "down":
		anim.flip_h = true
		if movement == 1:
			anim.play("front_walk")
		elif movement == 0:
			anim.play("front_idle")
	elif dir == "up":
		anim.flip_h = true
		if movement == 1:
			anim.play("back_walk")
		elif movement == 0:
			anim.play("back_idle")
	elif dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
			

func check_conveyor() -> Vector2:
	if ground_layer == null: 
		return Vector2.ZERO
		
	# Update grid_pos based on current position
	grid_pos = ground_layer.local_to_map(global_position)
	var tile_data = ground_layer.get_cell_tile_data(grid_pos)
	
	if tile_data:
		var force = tile_data.get_custom_data("force_dir")
		if force != null:
			return Vector2(force) # Return the direction found
	return Vector2.ZERO

func update_animation(direction: Vector2):
	var anim = $AnimatedSprite2D
	if direction == Vector2.RIGHT:
		anim.flip_h = false
		anim.play("side_idle")
		lastDirection = "right"
	elif direction == Vector2.UP:
		anim.flip_h = true
		anim.play("back_idle")
		lastDirection = "up"
	elif direction == Vector2.DOWN:
		anim.flip_h = true
		anim.play("front_idle")
		lastDirection = "down"
	elif direction == Vector2.LEFT:
		anim.flip_h = true
		anim.play("side_idle")
		lastDirection = "left"
		
func is_ice_tile(world_pos: Vector2) -> bool:
	
	if ground_layer == null:
		return false
	
	var grid = ground_layer.local_to_map(world_pos)
	var tile_data = ground_layer.get_cell_tile_data(grid)
	
	if tile_data == null:
		return false 
	
	if not tile_data.has_custom_data("is_ice"):
		return false
		
	return tile_data.get_custom_data("is_ice") == true
	
func slide_step():
	# Lock Velocity
	velocity = slide_dir * speed
	play_anim(1)
	
	#stop sliding if ice ends
	if not is_ice_tile(global_position):
		stop_sliding()

func stop_sliding():
	is_sliding = false
	slide_dir = Vector2.ZERO
	play_anim(0)

func get_speed_modifier() -> float:
	
	var grid = ground_layer.local_to_map(global_position)
	var tile_data = ground_layer.get_cell_tile_data(grid)
	
	if tile_data.has_custom_data("slow_multiplier"):
		is_slow = true
		if tile_data.get_custom_data("slow_multiplier") == 0:
			return 1
		else:
			return tile_data.get_custom_data("slow_multiplier")
			
	if not tile_data:
		return 1
		
	if tile_data.get_custom_data("slow_multiplier") == 0:
		return 1
		
	return 1
	

		
	
