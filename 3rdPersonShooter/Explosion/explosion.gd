extends Node3D

@export var lifetime: float = 0.35
@export var start_scale: float = 0.25
@export var end_scale: float = 1.0
@export var color: Color = Color(1.0, 0.6, 0.15)

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var _size_multiplier: float = 1.0

func setup(size_multiplier: float = 1.0) -> void:
	_size_multiplier = size_multiplier

func _ready() -> void:
	start_scale *= _size_multiplier
	end_scale *= _size_multiplier
	scale = Vector3.ONE * start_scale

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat

	light.light_color = color
	light.light_energy = 4.0 * _size_multiplier
	light.omni_range = 6.0 * _size_multiplier

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE * end_scale, lifetime)
	tween.tween_property(mat, "albedo_color:a", 0.0, lifetime)
	tween.tween_property(light, "light_energy", 0.0, lifetime)
	await tween.finished
	queue_free()
