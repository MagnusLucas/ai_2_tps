extends Node2D
class_name MyGraphNode

var connected_edges = []

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT 
		and get_global_mouse_position().distance_to(position) <= 4
		and event.is_pressed()):
		if !get_parent().path_beginning:
			get_parent().path_beginning = self
		else:
			get_parent().path_end = self
			get_parent().AStar(get_parent().path_beginning, self)
		queue_redraw()

func _draw() -> void:
	const color = Color.CADET_BLUE
	if get_parent().path_beginning == self:
		draw_circle(Vector2.ZERO, 4, Color.CHOCOLATE)
	elif get_parent().path_end == self:
		draw_circle(Vector2.ZERO, 4, Color.DARK_BLUE)
	else:
		draw_circle(Vector2.ZERO, 4, Color(color, Globals.GRAPH_VISIBILITY))
