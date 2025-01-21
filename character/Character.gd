extends Node2D
class_name Character

const VISIBILITY_CONE = 90.0 # in degrees
const ROTATION_SPEED = 10.0
const WALK_SPEED = 30.0
const DAMAGE = 5

static var MAX_HP = 100
static var MAX_AMMO_SUPPLY = 20
static var MAX_ARMOR_SUPPLY = 100

var HP = MAX_HP
var ammo_supply = MAX_AMMO_SUPPLY
var armor_supply = MAX_ARMOR_SUPPLY

var memory : Memory
var current_state : State
var previous_state : State

var velocity : Vector2 = Vector2.ZERO
const speed = Globals.RADIUS * 10
var in_focus = false

const rotation_speed = 30./360 * 2 * PI


enum State{
	RANDOM_WALK,
	FIGHT,
	FLEE,
	COLLECT_AMMO,
	COLLECT_HEALING,
	COLLECT_ARMOR,
}

var shooting : bool = false
var map_graph : MyGraph
var starting_position : Vector2

signal notice_collectible(collectible : Collectible)

var memory_timer : Timer
const MEMORY_INTERVAL = 2
const SHOOTING_ACCUMULATOR = 0.2

# For generating the graph. Checks if the character can be placed in a_position where you want to create a node
static func check_if_placeable(a_position, a_obstacles):
	for obstacle in a_obstacles:
		const accuracy_divisor = 36 # bigger => higher accuracy
		for angle_to_check in range(0., 360., 360. / accuracy_divisor):
			var in_radians = deg_to_rad(angle_to_check)
			if obstacle.is_point_inside(a_position + Vector2.RIGHT.rotated(in_radians) * Globals.RADIUS):
				return false
	return true

# Places character on a tile without other character, randomizes it's rotation
func _init(graph : MyGraph, other_characters : Dictionary) -> void:
	map_graph = graph
	var placing = graph.get_random_node()
	while other_characters.has(placing):
		placing = graph.get_random_node()
	other_characters[placing] = self
	starting_position = placing.position
	position = placing.position
	rotation = 2 * PI / 8 * randi_range(0, 7)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	memory = Memory.new()
	previous_state = current_state
	current_state = State.RANDOM_WALK
	notice_collectible.connect(_on_collectible_noticed)
	memory_timer = Timer.new()
	add_child(memory_timer)
	memory_timer.start(MEMORY_INTERVAL * 1.5)
	memory_timer.connect("timeout", on_timeout)

func on_timeout():
	memory.attacking_enemies = []
	memory_timer.start(MEMORY_INTERVAL)

func reset() -> void:
	shooting = false
	position = starting_position
	rotation = 2 * PI / 8 * randi_range(0, 7)
	HP = MAX_HP
	armor_supply = MAX_ARMOR_SUPPLY
	ammo_supply = MAX_AMMO_SUPPLY
	velocity = Vector2.ZERO
	memory = Memory.new()
	previous_state = current_state
	current_state = State.RANDOM_WALK

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT 
		and get_global_mouse_position().distance_to(position) <= Globals.RADIUS
		and event.is_pressed()):
		in_focus = !in_focus

func _on_collectible_noticed(collectible : Collectible):
	if collectible is HealthPack:
		memory.last_seen_healing = collectible.position
	elif collectible is Ammo:
		memory.last_seen_ammo = collectible.position
	elif collectible is Armor:
		memory.last_seen_armor = collectible.position

var accumulate_time = 0

func is_in_vision(object_position : Vector2) -> bool:
	var local_angle = (object_position - position).angle_to(Vector2(1,0).rotated(rotation))
	if (abs(local_angle) < VISIBILITY_CONE/2/360 * 2*PI
		and MyGraphEdge.doesnt_intersect_obstacle(position, object_position, get_parent().obstacles)):
		return true
	return false

func watch_out_for_enemies(characters : Array) -> void:
	var seen : Array[Vector2] = []
	for character in characters:
		if character != self:
			if is_in_vision(character.position):
				seen.append(character.position)
	if seen.size() > 0:
		if !memory.engaged_enemy or !seen.has(memory.engaged_enemy):
			memory.engaged_enemy = seen.front()
	else:
		memory.engaged_enemy = null
		shooting = false
	memory.seen_enemies = seen

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	accumulate_time += delta
	match current_state:
		State.RANDOM_WALK:
			previous_state = current_state
			if HP < 51:
				if not memory.attacking_enemies == []:
					current_state = State.FLEE
				else:
					current_state = State.COLLECT_HEALING
			elif armor_supply < 51:
				if not memory.attacking_enemies == []:
					current_state = State.FLEE
				else:
					current_state = State.COLLECT_ARMOR
			elif memory.seen_enemies:
				current_state = State.FIGHT
			else:
				current_state = State.RANDOM_WALK
				wander()
		State.FIGHT:
			if ammo_supply < 1:
					previous_state = current_state
					current_state = State.COLLECT_AMMO
			elif memory.engaged_enemy:
				fight(memory.engaged_enemy, delta)
				memory.currently_followed_path = get_parent().graph.find_path(position, memory.engaged_enemy)
				follow_path()
				if HP < 51:
					previous_state = current_state
					current_state = State.FLEE
			else:
				previous_state = current_state
				current_state = State.RANDOM_WALK
		State.FLEE:
			var closest_attacking_enemy = null
			var distance = INF
			for enemy in memory.attacking_enemies:
				if position.distance_to(enemy) < distance:
					distance = position.distance_to(enemy)
					closest_attacking_enemy = enemy
			evade(closest_attacking_enemy)
			if not memory.attacking_enemies:
				previous_state = current_state
				current_state = State.COLLECT_HEALING
		State.COLLECT_AMMO:
			collect(get_parent().get_closest_collectible(Ammo, position))
			if ammo_supply == MAX_AMMO_SUPPLY:
				previous_state = current_state
				current_state = State.RANDOM_WALK
			#collect(memory.last_seen_ammo)
		State.COLLECT_HEALING:
			collect(get_parent().get_closest_collectible(HealthPack, position))
			if HP == MAX_HP:
				previous_state = current_state
				current_state = State.RANDOM_WALK
			#collect(memory.last_seen_healing)
		State.COLLECT_ARMOR:
			collect(get_parent().get_closest_collectible(Armor, position))
			if armor_supply == MAX_ARMOR_SUPPLY:
				previous_state = current_state
				current_state = State.RANDOM_WALK
			#collect(memory.last_seen_armor)
	position += velocity * speed * delta
	if memory.engaged_enemy:
		var angle_to_enemy = (memory.engaged_enemy - position).angle()
		rotation = move_toward(rotation, angle_to_enemy, delta)
		#if ammo_supply > 0 and HP > MAX_HP/2:
			#current_state = State.FIGHT
		#else:
			#memory.currently_followed_path = []
			#velocity = Vector2.ZERO
			#current_state = State.FLEE
			#current_state = State.COLLECT_AMMO #for now
	else:
		rotation += rotation_speed * delta
	if in_focus:
		get_parent().get_child(0).text = ("HP: " + str(HP) +"/" + str(MAX_HP) + 
				" Armor: " + str(armor_supply) + "/" + str(MAX_ARMOR_SUPPLY) +
				" Ammo: " + str(ammo_supply) + "/" + str(MAX_AMMO_SUPPLY))
	watch_out_for_enemies(get_parent().characters.values())
	queue_redraw()
## TODO - when spots enemy fights if has hp+ammo, flees otherwise
func wander():
	if previous_state != State.RANDOM_WALK or memory.currently_followed_path == []:
		memory.currently_followed_path = map_graph.find_path(position, map_graph.get_random_node().position)
	follow_path()

func take_damage(damage_value, attacking_enemy):
	memory.attacking_enemies.append(attacking_enemy)
	if armor_supply > damage_value:
		armor_supply -= damage_value
		return
	elif armor_supply > 0:
		damage_value -= armor_supply
		armor_supply = 0
	HP -= damage_value
	if HP <= 0:
		reset()

var shooting_accumulator = 0
## 
func fight(enemy : Vector2, delta):
	if enemy:
		shooting = true
		shooting_accumulator += delta
		if shooting_accumulator > SHOOTING_ACCUMULATOR:
			shooting_accumulator -= SHOOTING_ACCUMULATOR
			ammo_supply -= 1
			get_parent().get_enemy(enemy, self).take_damage(DAMAGE, position)

## TODO - until not seen??? then collect hp/ammo/armor
func evade(enemy_position): # this is flee
	if enemy_position:
		var hiding_spot = map_graph.find_hiding_spot(enemy_position, position)
		memory.currently_followed_path = map_graph.find_path(position, hiding_spot)
		follow_path()

## Handles collecting collectibles
func collect(object_position : Vector2):
	# if not following path yet, find path
	if (!memory.currently_followed_path or previous_state != current_state) and object_position:
		memory.currently_followed_path = get_parent().graph.find_path(position, object_position)
		follow_path()
		if position.distance_to(memory.currently_followed_path.back()) < 10:
			var collectible_position  : Vector2 = memory.currently_followed_path.back()
			memory.currently_followed_path = []
			velocity = Vector2.ZERO
			var node = map_graph.find_closest_node(collectible_position)
			if !get_parent().collectibles[node]:
				print("err!")
			get_parent().collectibles[node]._on_collected(self)
	# if following, keep following
	elif memory.currently_followed_path:
		follow_path()
	# didn't see object, maybe will spot when wandering
	#elif !memory.currently_followed_path and !object_position:
		#wander()

# Follows remembered path
func follow_path():
	if position.distance_to(memory.currently_followed_path[0]) < 5:
		memory.currently_followed_path.remove_at(0)
	if memory.currently_followed_path != []:
		velocity = (Vector2(memory.currently_followed_path[0]) - position).normalized()
	else:
		velocity = Vector2.ZERO

# Draws the character on screen
func _draw() -> void:
	const WHAT_THEY_SEE_COLOR = Color.BLACK
	const VISIBILITY_LENGTH = Globals.RADIUS * 30
	
	#body
	draw_circle(Vector2i.ZERO, Globals.RADIUS, Color.RED)
	
	#what directions they see
	draw_arc(Vector2i.ZERO, VISIBILITY_LENGTH, -deg_to_rad(VISIBILITY_CONE/2), deg_to_rad(VISIBILITY_CONE/2), 10, WHAT_THEY_SEE_COLOR)
	draw_line(Vector2i.ZERO, (Vector2.RIGHT * VISIBILITY_LENGTH).rotated(deg_to_rad(VISIBILITY_CONE/2)), WHAT_THEY_SEE_COLOR)
	draw_line(Vector2i.ZERO, (Vector2.RIGHT * VISIBILITY_LENGTH).rotated(-deg_to_rad(VISIBILITY_CONE/2)), WHAT_THEY_SEE_COLOR)

	#draws health bar
	var length = 26.0
	var health_bar_outline = Rect2(Vector2(-length/2, -20), Vector2(length + 2,7))
	var health_bar = Rect2(Vector2(-length/2, -20), Vector2(length * HP / MAX_HP,5))
	var armor_bar = Rect2(Vector2(-length/2, -20), Vector2(length * armor_supply / MAX_ARMOR_SUPPLY,5))
	draw_set_transform(Vector2i.ZERO, -rotation)
	draw_rect(health_bar_outline, Color.BLACK, false, 1)
	draw_rect(health_bar, Color.LAWN_GREEN)
	var armor_bar_color = Color(Color.CADET_BLUE, 0.8)
	draw_rect(armor_bar, armor_bar_color)

	#followed path
	var color
	match current_state:
		State.RANDOM_WALK:
			color = Color.SKY_BLUE
		State.COLLECT_AMMO:
			color = Color.DIM_GRAY
		State.COLLECT_HEALING:
			color = Color.LAWN_GREEN
		State.COLLECT_ARMOR:
			color = Color.CADET_BLUE
		State.FIGHT:
			color = Color.YELLOW
		State.FLEE:
			color = Color.MEDIUM_SLATE_BLUE
	for point in range(memory.currently_followed_path.size()-1):
		draw_line(Vector2(memory.currently_followed_path[point]) - position, Vector2(memory.currently_followed_path[point+1]) - position, color)
	if memory.currently_followed_path != []:
		draw_line(Vector2.ZERO, Vector2(memory.currently_followed_path[0]) - position, color)

	if in_focus:
		draw_circle(Vector2.ZERO, Globals.RADIUS, Color.WHITE, false, 1)
		for enemy_position in memory.seen_enemies:
			draw_line(Vector2.ZERO, enemy_position - position, Color.WEB_GREEN)
		if memory.engaged_enemy:
			draw_circle(memory.engaged_enemy - position, 4, Color.WHITE, false, 1)

	if shooting:
		draw_line(Vector2.ZERO, memory.engaged_enemy - position, Color.RED, 4)
