extends Area2D
var speed = 200
const EXPLOSION = preload("uid://cdyybho1hbnsq")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	translate(Vector2.LEFT * speed * delta)
	position.y += sin(position.x * delta) * 0.8


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Projectile"):
		var explosion = EXPLOSION.instantiate()
		explosion.global_position = global_position
		add_sibling(explosion)
		queue_free()
