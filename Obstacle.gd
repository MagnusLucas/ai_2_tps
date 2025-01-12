extends Node2D
class_name Obstacle

var vertices

func _init(a_position, a_vertices) -> void:
	vertices = a_vertices
	position = a_position

func _draw() -> void:
	draw_colored_polygon(vertices, Color.BROWN)

func is_point_inside(point) -> bool:
	return Geometry2D.is_point_in_polygon(point - position, vertices)
