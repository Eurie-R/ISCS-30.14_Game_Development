extends CharacterBody3D

signal died

@export var max_health: int = 3
@export var explosion_scene: PackedScene
@export var hit_flash_color: Color = Color(1.8, 0.4, 0.4)
@export var death_explosion_scale: float = 2.5

var health: int
var _flashing: bool = false

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	health = max_health

func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return
	health -= amount
	_flash()
	if health <= 0:
		_die()

func _flash() -> void:
	if mesh == null or _flashing:
		return
	_flashing = true
	var base_mat := mesh.mesh.surface_get_material(0) if mesh.mesh and mesh.mesh.get_surface_count() > 0 else null
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = hit_flash_color
	flash_mat.emission_enabled = true
	flash_mat.emission = hit_flash_color
	flash_mat.emission_energy_multiplier = 1.5
	mesh.material_override = flash_mat
	await get_tree().create_timer(0.08).timeout
	mesh.material_override = null
	_flashing = false

func _die() -> void:
	died.emit()
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		if explosion.has_method("setup"):
			explosion.setup(death_explosion_scale)
	queue_free()
