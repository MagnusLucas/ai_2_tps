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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		#print(Character.check_if_placable(get_global_mouse_position(),get_parent().obstacles))
		Character.check_if_placeable(get_global_mouse_position(),get_parent().obstacles)
