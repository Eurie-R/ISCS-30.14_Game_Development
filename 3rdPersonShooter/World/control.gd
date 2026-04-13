extends Control

@export var reticle_offset: Vector2 = Vector2(20, 0)
@export var reticle_color: Color = Color.WHITE

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = get_viewport().get_visible_rect().size * 0.5 + Vector2(20, 0)

	draw_line(center + Vector2(-8, 0), center + Vector2(-2, 0), reticle_color, 2.0)
	draw_line(center + Vector2(2, 0), center + Vector2(8, 0), reticle_color, 2.0)
	draw_line(center + Vector2(0, -8), center + Vector2(0, -2), reticle_color, 2.0)
	draw_line(center + Vector2(0, 2), center + Vector2(0, 8), reticle_color, 2.0)
	draw_circle(center, 1.5, reticle_color)
