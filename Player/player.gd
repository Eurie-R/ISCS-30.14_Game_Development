extends CharacterBody3D

@export var bullet_scene: PackedScene

@onready var cam: Camera3D = $Camera/Camera3D
@onready var muzzle: Node3D = $WeaponMuzzle
@export var reticle_screen_offset: Vector2 = Vector2(24, 0)

func set_velocity_from_motion(vel: Vector3) -> void:
	velocity = vel

func _physics_process(delta: float) -> void:
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Shoot"):
		fire()

func fire() -> void:
	if bullet_scene == null:
		push_warning("bullet_scene is not assigned on Player.")
		return

	var target: Vector3 = get_aim_target()

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle.global_position

	var direction: Vector3 = (target - muzzle.global_position).normalized()

	if bullet.has_method("setup"):
		bullet.setup(direction)

func get_aim_target() -> Vector3:
	var screen_center: Vector2 = get_viewport().get_visible_rect().size * 0.5 + reticle_screen_offset

	var ray_origin: Vector3 = cam.project_ray_origin(screen_center)
	var ray_dir: Vector3 = cam.project_ray_normal(screen_center)

	var ray_length: float = 1000.0
	var ray_end: Vector3 = ray_origin + ray_dir * ray_length

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	if result:
		return result.position

	return ray_end
