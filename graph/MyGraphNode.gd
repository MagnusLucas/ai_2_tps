extends Node2D
class_name MyGraphNode

var connected_edges = []

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4, Color.CADET_BLUE)
