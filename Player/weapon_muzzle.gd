extends Marker3D
@export var bullet_scene: PackedScene
@onready var cam: Camera3D = $Camera/Camera3D
@onready var muzzle: Node3D = $WeaponMuzzle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func get_aim_target() -> Vector3:
	var screen_center: Vector2 = get_viewport().get_visible_rect().size * 0.5

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

func fire() -> void:
	var target: Vector3 = get_aim_target()

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle.global_position

	var direction: Vector3 = (target - muzzle.global_position).normalized()
	bullet.setup(direction)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Shoot"):
		fire()
