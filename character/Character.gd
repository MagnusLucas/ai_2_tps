extends Node2D
class_name Character

const VISIBILITY_CONE = 60.0
const ROTATION_SPEED = 10.0
const WALK_SPEED = 30.0

var HP = 100
var ammo_supply = 20
var armor_supply = 100

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


# For generating the graph. Checks if the character can be placed in a_position where you want to create a node
static func check_if_placeable(a_position, a_obstacles):
	for obstacle in a_obstacles:
		const accuracy_divisor = 36 # bigger => higher accuracy
		for angle_to_check in range(0., 360., 360. / accuracy_divisor):
			var in_radians = deg_to_rad(angle_to_check)
			if obstacle.is_point_inside(a_position + Vector2.RIGHT.rotated(in_radians) * Globals.RADIUS):
				return false
	return true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	memory = Memory.new()
	current_state = State.RANDOM_WALK


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
	
	#TODO: health bar
