extends Node2D
class_name Character

const VISIBILITY_CONE = 60.0
const ROTATION_SPEED = 10.0
const WALK_SPEED = 30.0

const MAX_HP = 100
const MAX_AMMO_SUPPLY = 20
const MAX_ARMOR_SUPPLY = 100

var HP = MAX_HP
var ammo_supply = MAX_AMMO_SUPPLY
var armor_supply = MAX_ARMOR_SUPPLY

var memory : Memory
var current_state : State

enum State{
	RANDOM_WALK,
	FIGHT,
	FLEE,
	COLLECT_AMMO,
	COLLECT_HEALING,
	COLLECT_ARMOR,
}

signal notice_collectible(collectible : Collectible)

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
	var placing = graph.get_random_node()
	while other_characters.has(placing):
		placing = graph.get_random_node()
	other_characters[placing] = self
	position = placing.position
	rotation = 2 * PI / 8 * randi_range(0, 7)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	memory = Memory.new()
	current_state = State.RANDOM_WALK
	notice_collectible.connect(_on_collectible_noticed)

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT 
		and get_global_mouse_position().distance_to(position) <= Globals.RADIUS
		and event.is_pressed()):
		get_parent().get_child(0).text = ("HP: " + str(HP) +"/" + str(MAX_HP) + 
				" Armor: " + str(armor_supply) + "/" + str(MAX_ARMOR_SUPPLY) +
				" Ammo: " + str(ammo_supply) + "/" + str(MAX_AMMO_SUPPLY))
		armor_supply -= 10
		queue_redraw()

func _on_collectible_noticed(collectible : Collectible):
	if collectible is HealthPack:
		memory.last_seen_healing = collectible.position
	elif collectible is Ammo:
		memory.last_seen_ammo = collectible.position
	elif collectible is Armor:
		memory.last_seen_armor = collectible.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	match current_state:
		State.RANDOM_WALK:
			wander()
		State.FIGHT:
			fight(memory.engaged_enemy)
		State.FLEE:
			evade(memory.engaged_enemy)
			for enemy_position in memory.non_engaged_seen_enemies:
				evade(enemy_position)
		State.COLLECT_AMMO:
			collect(memory.last_seen_ammo)
		State.COLLECT_HEALING:
			collect(memory.last_seen_healing)
		State.COLLECT_ARMOR:
			collect(memory.last_seen_armor)

## TODO - when spots enemy fights if has hp+ammo, flees otherwise
func wander():
	pass

## TODO - change state if low hp/ammo to flee
func fight(enemy : Vector2i):
	pass

## TODO - until not seen??? then collect hp/ammo/armor
func evade(enemy_position : Vector2i):
	pass

## TODO (look inside)
func collect(object_position : Vector2i):
	# if not following path yet, find path
		if !memory.currently_followed_path and object_position:
			memory.currently_followed_path = get_parent().graph.find_path(position, object_position)
			# if objects can be placed not on nodes, here should be added to head towards object from current (closest) node
			## TODO actually collecting, then change state
		# if following, keep following
		elif memory.currently_followed_path:
			follow_path(memory.currently_followed_path)
		# didn't see object, maybe will spot when wandering
		elif !memory.currently_followed_path and !object_position:
			wander()

## TODO - > remove visited nodes
func follow_path(path : Array[Vector2i]):
	pass


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
	var health_bar_outline = Rect2(Vector2i(-25/2, -20), Vector2i(27,7))
	var health_bar = Rect2(Vector2i(-25/2, -20), Vector2i(25 * HP / MAX_HP,5))
	var armor_bar = Rect2(Vector2i(-25/2, -20), Vector2i(25 * armor_supply / MAX_ARMOR_SUPPLY,5))
	draw_set_transform(Vector2i.ZERO, -rotation)
	draw_rect(health_bar_outline, Color.BLACK, false, 1)
	draw_rect(health_bar, Color.LAWN_GREEN)
	var armor_bar_color = Color(Color.CADET_BLUE, 0.8)
	draw_rect(armor_bar, armor_bar_color)
