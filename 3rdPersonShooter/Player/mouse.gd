extends Node3D

# --- Node References ---
@export var character = get_parent() as CharacterBody3D
@export var camera: Camera3D
@export var edge_spring_arm: SpringArm3D
@export var rear_spring_arm: SpringArm3D

# --- Configuration ---
@export var camera_alignment_speed: float = 0.2
@export var rear_aim_arm_length: float = 0.5
@export var edge_aim_arm_length: float = 0.5
@export var aim_speed: float = 0.2
@export var aim_fov: float = 55

# --- Internal State ---
var camera_rotation: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.001
var max_y_rotation: float = 1.2

var camera_tween: Tween

# Store initial values to return to them after aiming
@onready var default_edge_spring_arm_length: float = edge_spring_arm.spring_length
@onready var default_rear_spring_arm_length: float = rear_spring_arm.spring_length
@onready var default_fov: float = camera.fov


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Handle mouse movement for rotation
	if event is InputEventMouseMotion:
		var mouse_event: Vector2 = event.screen_relative * mouse_sensitivity
		_camera_look(mouse_event)
		
	# Shoulder Swap
	if event.is_action_pressed("Swap"):
		_swap_camera()
		pass
	
	# Aiming
	if event.is_action_pressed("Aim"):
		_enter_aim()
		pass
	if event.is_action_released("Aim"):
		_exit_aim()
		pass

func _camera_look(mouse_movement: Vector2) -> void:
	camera_rotation += mouse_movement
	
	# Reset basis to prevent transform drift
	transform.basis = Basis()
	character.transform.basis = Basis()
	
	# Rotate character left/right (Y-axis)
	character.rotate_object_local(Vector3(0,1,0), -camera_rotation.x)
	# Rotate this node (the camera pivot) up/down (X-axis)
	rotate_object_local(Vector3(1,0,0), -camera_rotation.y)
	
	# Clamp vertical rotation to prevent the camera from flipping upside down
	camera_rotation.y = clamp(camera_rotation.y, -max_y_rotation, max_y_rotation)


func _enter_aim() -> void:
	if camera_tween:
		camera_tween.kill()
		
	camera_tween = get_tree().create_tween().set_parallel()
	
	camera_tween.tween_property(camera,"fov", aim_fov, aim_speed)
	camera_tween.tween_property(edge_spring_arm,"spring_length",edge_aim_arm_length*sign(edge_spring_arm.spring_length), aim_speed)
	camera_tween.tween_property(rear_spring_arm,"spring_length",rear_aim_arm_length, aim_speed)
	

func _exit_aim() -> void:
	if camera_tween:
		camera_tween.kill()   
	camera_tween = get_tree().create_tween().set_parallel()    
	camera_tween.tween_property(camera, "fov", default_fov, aim_speed)
	camera_tween.tween_property(edge_spring_arm, "spring_length", default_edge_spring_arm_length, aim_speed)
	camera_tween.tween_property(rear_spring_arm, "spring_length", default_rear_spring_arm_length, aim_speed)

func _swap_camera() -> void:
	default_edge_spring_arm_length = -default_edge_spring_arm_length
	_set_rear_arm(default_edge_spring_arm_length, camera_alignment_speed)
	
	
func _set_rear_arm(pos: float, speed: float) -> void:
	if camera_tween:
		camera_tween.kill()
		
	camera_tween = get_tree().create_tween()
	camera_tween.tween_property(edge_spring_arm, "spring_length", pos, speed)
