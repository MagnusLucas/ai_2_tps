extends Node2D
class_name MyGraphNode

var connected_edges = []

func _draw() -> void:
	const color = Color.CADET_BLUE
	draw_circle(Vector2.ZERO, 4, Color(color, Globals.GRAPH_VISIBILITY))
