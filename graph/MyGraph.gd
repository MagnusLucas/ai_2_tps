extends Node2D
class_name MyGraph

var nodes = {}
var edges = []

# To place things randomly in reachable areas of the map
func get_random_node():
	var node_keys = nodes.keys()
	var random_key = node_keys[randi_range(0, node_keys.size()-1)]
	return nodes[random_key]

# iteration aproach no partition Meadow
func find_closest_node(position_on_screen : Vector2i) -> MyGraphNode:
	var distance = 10000000000000
	var node
	for i in nodes:
		position_on_screen.distance_to(nodes[i].position)
		if (position_on_screen.distance_to(nodes[i].position)<distance):
			distance = position_on_screen.distance_to(nodes[i].position)
			node = i
	return nodes[node]

## TODO
func AStar(from : MyGraphNode, to : MyGraphNode) -> Array[MyGraphNode]:
	#dictionory assigns heurisitc by distance to target
	var heuristic_dic = {}
	for i in nodes:
		heuristic_dic[nodes[i]] = i.distance_to(to.position)
	
	#freaky way to do a set as dictionary 
	#set.add(value) <-> dict[value] = null
	#set.remove(value) <-> dict.erase(value)
	#set.has(value) <-> dict.has(value) or value in dict
	var open_set = {}
	open_set[from] = null
	#// For node n, cameFrom[n] is the node immediately preceding it on the cheapest path from the start
	#// to n currently known.
	var came_from = {}
#
	var g_score = {}
	for i in nodes:
		g_score[nodes[i]] = 10000000000000
	g_score[from] = 0
	var f_score = g_score.duplicate()
	f_score[from] = heuristic_dic[from]
	var current = from
	var tentative_g_score 
	while(not open_set.is_empty()):
		#print("aaaa")
		for i in open_set:
			print(f_score[current])
			print(f_score[i])
			print("/n")
			if(f_score[current]<f_score[i]):
				#print("aredawe")
				current = i
		if(current == to):
			var ar = [current]
			return ar
				 #return reconstruct_path(cameFrom, current)
			
		#print(open_set.erase(current))
		open_set.erase(current)
		#if(open_set.erase(current)):
			#return[]
			#print(open_set)
		for j in current.connected_edges:
				#print(current.connected_edges)
			tentative_g_score = g_score[current] + j.cost
				#print(tentative_g_score)
				#print(g_score[j.neighbour(current)])
			#print("bbbbb")
			if tentative_g_score < g_score[j.neighbour(current)]:
				#print("ccccc")
				var neighbour = j.neighbour(current)
				came_from[neighbour] = current 
				g_score[neighbour] = tentative_g_score
				f_score[neighbour] = tentative_g_score + heuristic_dic[neighbour]
				if not open_set.has(neighbour):
					#print("ddddd")
					open_set[neighbour] = null
						
					#print("bbb")
				   



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
						
