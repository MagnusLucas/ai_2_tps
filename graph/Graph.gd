extends Node2D
class_name MyGraph

var nodes = {}
var edges = []

func _ready() -> void:
	var obstacles = get_parent().obstacles
	var window_size = get_viewport_rect().size
	const ACCURACY = Globals.RADIUS * 4
	
	# TODO: This creates a proper graph, but is not a flood fill, so needs fixing
	for y in range(Globals.RADIUS, window_size.y - Globals.RADIUS, ACCURACY):
		for x in range(Globals.RADIUS, window_size.x - Globals.RADIUS, ACCURACY):
			var node_position = Vector2(x, y)
			if Character.check_if_placable(node_position, obstacles):
				var node = MyGraphNode.new()
				node.position = node_position
				add_child(node)
				nodes[node_position] = node
				for other_node_position in [Vector2(x - ACCURACY, y - ACCURACY), 
				Vector2(x, y - ACCURACY),
				Vector2(x + ACCURACY, y - ACCURACY), 
				Vector2(x - ACCURACY, y)]:
					if (nodes.has(other_node_position) and 
					MyGraphEdge.doesnt_intersect_obstacle(node.position, other_node_position, obstacles)):
						# the second part in if is needed to not create paths going through obstacles
						# just because there is a node on the other side of the obstacle
						var other_node = nodes[other_node_position]
						var edge = MyGraphEdge.new()
						edge.connected_nodes["from"] = node
						edge.connected_nodes["to"] = other_node
						node.connected_edges.append(edge)
						other_node.connected_edges.append(edge)
						add_child(edge)
						edges.append(edge)
