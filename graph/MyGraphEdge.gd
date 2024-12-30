extends Node2D
class_name MyGraphEdge

var connected_nodes = {"from" : null, "to" : null}
var cost

# Checks if the edge wouldn't intersect any obstacles
static func doesnt_intersect_obstacle(from, to, obstacles):
	var polyline = PackedVector2Array([from, to])
	for obstacle in obstacles:
		var polygon = obstacle.vertices.duplicate()
		for i in polygon.size():
			polygon[i] += obstacle.position
		if Geometry2D.intersect_polyline_with_polygon(polyline, polygon):
			return false
	return true

func _draw() -> void:
	if connected_nodes["from"] != null and connected_nodes["to"] != null:
		draw_line(connected_nodes["from"].position, connected_nodes["to"].position, Color.SKY_BLUE)
