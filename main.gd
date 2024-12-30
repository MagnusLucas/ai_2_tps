extends Node2D

var obstacles = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(5):
		create_obstacle()
	add_child(MyGraph.new())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

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
