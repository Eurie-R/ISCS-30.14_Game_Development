extends Node3D

@export var character: CharacterBody3D
@export var camera: Camera3D

@export var mouse_sensitivity: float = 0.002
@export var aim_mouse_sensitivity: float = 0.0014
@export var max_pitch: float = 1.0

@export var default_camera_offset: Vector3 = Vector3(0.50, 0.00, 1.90)
@export var aim_camera_offset: Vector3 = Vector3(0.30, 0.02, 1.15)

@export var default_fov: float = 75.0
@export var aim_fov: float = 52.0
@export var sprint_fov: float = 85.0

@export var shoulder_offset: float = 0.50
@export var transition_speed: float = 0.14

# Optional: slower turning while aiming feels more RE2-like
@export var normal_turn_scale: float = 1.0
@export var aim_turn_scale: float = 0.75

var pitch: float = 0.0
var aiming: bool = false
var sprinting: bool = false
var right_shoulder: bool = true
var camera_tween: Tween

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_camera_pose(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion:
		_handle_mouse_look(event)

	if event.is_action_pressed("Swap"):
		right_shoulder = !right_shoulder
		_apply_camera_pose()

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	var sensitivity: float = aim_mouse_sensitivity if aiming else mouse_sensitivity
	var turn_scale: float = aim_turn_scale if aiming else normal_turn_scale

	var mouse_x: float = event.screen_relative.x * sensitivity * turn_scale
	var mouse_y: float = event.screen_relative.y * sensitivity

	# In both modes the camera stays attached to the actor.
	# In aim mode, this is an in-place turn, not free orbit.
	character.rotate_y(-mouse_x)

	pitch -= mouse_y
	pitch = clamp(pitch, -max_pitch, max_pitch)
	rotation.x = pitch

func _apply_camera_pose(immediate: bool = false) -> void:
	var target_offset: Vector3 = aim_camera_offset if aiming else default_camera_offset
	target_offset.x = shoulder_offset if right_shoulder else -shoulder_offset

	var target_fov: float = default_fov
	if sprinting and not aiming:
		target_fov = sprint_fov
	elif aiming:
		target_fov = aim_fov

	if camera_tween:
		camera_tween.kill()

	if immediate:
		camera.position = target_offset
		camera.fov = target_fov
		return

	camera_tween = create_tween()
	camera_tween.set_trans(Tween.TRANS_SINE)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(camera, "position", target_offset, transition_speed)
	camera_tween.parallel().tween_property(camera, "fov", target_fov, transition_speed)

func enter_aim() -> void:
	aiming = true
	_apply_camera_pose()

func exit_aim() -> void:
	aiming = false
	_apply_camera_pose()

func enter_sprint() -> void:
	sprinting = true
	_apply_camera_pose()

func exit_sprint() -> void:
	sprinting = false
	_apply_camera_pose()

func _on_aim_entered() -> void:
	enter_aim()

func _on_aim_exited() -> void:
	exit_aim()

func _on_sprint_sprint_started() -> void:
	enter_sprint()

func _on_sprint_ended() -> void:
	exit_sprint()
