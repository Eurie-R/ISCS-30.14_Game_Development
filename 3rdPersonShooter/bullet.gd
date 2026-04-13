extends Area3D

@export var speed: float = 25.0
@export var lifetime: float = 2.0

var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func setup(direction: Vector3) -> void:
	velocity = direction.normalized() * speed
	look_at(global_position + direction.normalized(), Vector3.UP)

func _on_body_entered(body: Node) -> void:
	queue_free()
