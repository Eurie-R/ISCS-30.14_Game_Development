extends Area3D

@export var speed: float = 25.0
@export var lifetime: float = 2.0
@export var damage: int = 1
@export var explosion_scene: PackedScene
@export var impact_explosion_scale: float = 0.6

var velocity: Vector3 = Vector3.ZERO
var _done: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	if not _done:
		queue_free()

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func setup(direction: Vector3) -> void:
	velocity = direction.normalized() * speed
	look_at(global_position + direction.normalized(), Vector3.UP)

func _on_body_entered(body: Node) -> void:
	if _done:
		return
	_done = true

	if body.has_method("take_damage"):
		body.take_damage(damage)

	_spawn_impact_explosion()
	queue_free()

func _spawn_impact_explosion() -> void:
	if explosion_scene == null:
		return
	var explosion = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	if explosion.has_method("setup"):
		explosion.setup(impact_explosion_scale)
