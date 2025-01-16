extends Node2D
class_name MyGraph

var nodes = {}
var edges = []

# To place things randomly in reachable areas of the map
func get_random_node():
	var node_keys = nodes.keys()
	var random_key = node_keys[randi_range(0, node_keys.size())]
	return nodes[random_key]

# iteration aproach no partition Meadow
func find_closest_node(position_on_screen : Vector2i) -> MyGraphNode:
	var distance = 10000000000000
	var node
	for i in nodes:
		position_on_screen.distance_to(nodes[i])
		if (position_on_screen.distance_to(nodes[i])<distance):
			distance = position_on_screen.distance_to(nodes[i])
			node = i
	return nodes[node]

## TODO
func AStar(from : MyGraphNode, to : MyGraphNode) -> Array[MyGraphNode]:
	
#bool Raven_PathPlanner::CreatePathToPosition(Vector2D TargetPos,
#std::list<Vector2D>& path)

#//ClosestNodeToPosition = from
#//create an instance of the A* search class to search for a path between the
#//closest node to the bot and the closest node to the target position. This
#//A* search will utilize the Euclidean straight line heuristic
#typedef Graph_SearchAStar< Raven_Map::NavGraph, Heuristic_Euclid> AStar;
#AStar search(m_NavGraph,
#ClosestNodeToBot,
#ClosestNodeToTarget);
#//grab the path
#std::list<int> PathOfNodeIndices = search.GetPathToTarget();
#//if the search is successful convert the node indices into position vectors
#if (!PathOfNodeIndices.empty())
#{
#ConvertIndicesToVectors(PathOfNodeIndices, path);
#//remember to add the target position to the end of the path
#path.push_back(TargetPos);
#return true;
#}
#else
#{
#//no path found by the search
#return false;
#}
#}
	return []

# Checks if smoothing to particular edge would result in intersecting an obstacle
func can_smooth(from: Vector2i, to: Vector2i) -> bool:
	var obstacles = get_parent().obstacles
	var perpendicular = Vector2(to - from).normalized().rotated(2 * PI / 4) * Globals.RADIUS
	return (MyGraphEdge.doesnt_intersect_obstacle(from + perpendicular, to + perpendicular, obstacles) and 
			MyGraphEdge.doesnt_intersect_obstacle(from - perpendicular, to - perpendicular, obstacles))

# TODO
# Converts path from array of MyGraphNodes to array of Vector2i positions on screen 
# and smooths the path, making the agents walk not following graph edges
func path_smoothing(from : Vector2i, to : Vector2i, through : Array[MyGraphNode]) -> Array[Vector2i]:
	return []

func find_path(from : Vector2i, to : Vector2i) -> Array[Vector2i]:
	var from_closest_node : MyGraphNode = find_closest_node(from)
	var to_closest_node : MyGraphNode = find_closest_node(to)
	return path_smoothing(from, to, AStar(from_closest_node, to_closest_node))

func _ready() -> void:
	var obstacles = get_parent().obstacles
	var window_size = get_viewport_rect().size
	const ACCURACY = Globals.RADIUS * 4
	
	# TODO: This creates a proper graph, but is not a flood fill, so needs fixing
	for y in range(Globals.RADIUS, window_size.y - Globals.RADIUS, ACCURACY):
		for x in range(Globals.RADIUS, window_size.x - Globals.RADIUS, ACCURACY):
			var node_position = Vector2(x, y)
			if Character.check_if_placeable(node_position, obstacles):
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
						
						#thing for A* to work
						edge.cost = node.position.distance_to(other_node_position)
						
