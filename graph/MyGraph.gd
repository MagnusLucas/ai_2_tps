extends Node2D
class_name MyGraph

var nodes = {}
var edges = []

var path_beginning = null
var path_end = null

# To place things randomly in reachable areas of the map
func get_random_node():
	var node_keys = nodes.keys()
	var random_key = node_keys[randi_range(0, node_keys.size()-1)]
	return nodes[random_key]

func get_edge(from : MyGraphNode, to : MyGraphNode) -> MyGraphEdge:
	for edge in edges:
		if edge.connected_nodes == {"from" : from, "to" : to}:
			return edge
		elif edge.connected_nodes == {"from" : to, "to" : from}:
			return edge
	return null

# iteration aproach no partition Meadow
func find_closest_node(position_on_screen : Vector2i) -> MyGraphNode:
	var distance = INF
	var node
	for i in nodes:
		position_on_screen.distance_to(nodes[i].position)
		if (position_on_screen.distance_to(nodes[i].position)<distance):
			distance = position_on_screen.distance_to(nodes[i].position)
			node = i
	return nodes[node]

func reconstruct_path(cameFrom : Dictionary, current : MyGraphNode) -> Array[MyGraphNode]:
	var total_path : Array[MyGraphNode] = [current]
	while current in cameFrom.keys():
		current = cameFrom[current]
		total_path.push_front(current)
	return total_path


func AStar(from : MyGraphNode, to : MyGraphNode) -> Array[MyGraphNode]:
	#dictionory assigns heurisitc by distance to target
	var heuristic_dic = {}
	for node_position in nodes:
		heuristic_dic[nodes[node_position]] = node_position.distance_to(to.position)
	
	
	var open_set = [] 
	open_set.append(from)
	#// For node n, cameFrom[n] is the node immediately preceding it on the cheapest path from the start
	#// to n currently known.
	var came_from = {}
#
	var g_score = {}
	for i in nodes:
		g_score[nodes[i]] = INF
	g_score[from] = 0
	var f_score = g_score.duplicate()
	f_score[from] = heuristic_dic[from]
	
	while(not open_set.is_empty()):
		#current := the node in openSet having the lowest fScore[] value
		var current = open_set[0]
		for node in open_set:
			if(f_score[current]>f_score[node]):
				current = node
		
		
		if(current == to):
			return reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		for edge in current.connected_edges:
			var tentative_g_score = g_score[current] + edge.cost
			if tentative_g_score < g_score[edge.neighbour(current)]:
				var neighbour = edge.neighbour(current)
				came_from[neighbour] = current 
				g_score[neighbour] = tentative_g_score
				f_score[neighbour] = tentative_g_score + heuristic_dic[neighbour]
				if not open_set.has(neighbour):
					open_set.append(neighbour)

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
						
