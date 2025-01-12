extends Node2D

var obstacles = []
var graph : MyGraph = null
var characters = []

# Called when the node enters the scene tree for the first time.
# Places obstacles, creates the graph and randomly places players in nodes of the graph
func _ready() -> void:
	for i in range(5):
		create_obstacle()
	graph = MyGraph.new()
	add_child(graph)
	for i in 4:
		var character = Character.new()
		character.position = graph.get_random_node().position
		character.rotation = 2 * PI / 8 * randi_range(0, 7)
		var correct_position = false
		while not correct_position:
			correct_position = true
			for other in characters:
				if character.position == other.position:
					correct_position = false
					character.position = graph.get_random_node().position
		add_child(character)
		characters.append(character)

# Creates obstacle by picking 3-6 random points in a radius of MAX_RADIUS_SIZE,
# places it in a random position, but within window borders.
# Adds as a child of this and to obstacles array
func create_obstacle():
	var window_size = get_viewport_rect().size
	var vertex_count = randi_range(3, 6)
	const MAX_RADIUS_SIZE = 100
	var vertices = []
	
	# evenly distributing angles between vertices, randomizing their distance from the center of obstacle
	for angle in range(0, 2*PI, 2*PI/vertex_count):
		vertices.append(Vector2.RIGHT.rotated(angle) * randf_range(0., MAX_RADIUS_SIZE))
	
	var obstacle_position = Vector2(
		randi_range(MAX_RADIUS_SIZE, window_size.x - MAX_RADIUS_SIZE),
		randi_range(MAX_RADIUS_SIZE, window_size.y - MAX_RADIUS_SIZE))
	
	#assuring obstacles don't overlap
	var correctly_placed = false
	while not correctly_placed:
		correctly_placed = true
		for obstacle in obstacles:
			if obstacle_position.distance_to(obstacle.position) < 2 * MAX_RADIUS_SIZE:
				correctly_placed = false
		if not correctly_placed:
			obstacle_position = Vector2(
				randi_range(MAX_RADIUS_SIZE, window_size.x - MAX_RADIUS_SIZE),
				randi_range(MAX_RADIUS_SIZE, window_size.y - MAX_RADIUS_SIZE))
	
	var obstacle = Obstacle.new(obstacle_position, PackedVector2Array(vertices))
	obstacles.append(obstacle)
	add_child(obstacle)
