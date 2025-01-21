extends Node2D
class_name MyGraphEdge

var connected_nodes = {"from" : null, "to" : null}
var cost

# Checks if the edge wouldn't intersect any obstacles
static func doesnt_intersect_obstacle(from : Vector2, to : Vector2, obstacles):
	var egde = PackedVector2Array([from, to])
	for obstacle in obstacles:
		var polygon = obstacle.vertices.duplicate()
		for i in polygon.size():
			polygon[i] += obstacle.position
		if Geometry2D.intersect_polyline_with_polygon(egde, polygon):
			return false
	return true

func _draw() -> void:
	if connected_nodes["from"] != null and connected_nodes["to"] != null:
		const color = Color.SKY_BLUE
		draw_line(connected_nodes["from"].position, connected_nodes["to"].position, Color(color, Globals.GRAPH_VISIBILITY))
		
func neighbour(node : MyGraphNode):
	if(connected_nodes.from == node):
		return connected_nodes.to
	elif(connected_nodes.to == node):
		return connected_nodes.from
	else:
		return null
