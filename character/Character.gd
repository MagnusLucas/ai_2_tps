extends Node2D
class_name Character

const VISIBILITY_CONE = 60.0
const ROTATION_SPEED = 10.0
const WALK_SPEED = 30.0

var HP = 100
var healing_supply = 2
var ammo_supply = 20
var armor_supply = 100

enum State{
	RANDOM_WALK,
	FIGHT,
	FLEE,
	COLLECT_AMMO,
	COLLECT_HEALING,
	COLLECT_ARMOR,
}

static func check_if_placable(a_position, a_obstacles):
	for obstacle in a_obstacles:
		const accuracy = 36
		for angle_to_check in range(0., 360., 360. / accuracy):
			var in_radians = deg_to_rad(angle_to_check)
			if obstacle.is_point_inside(a_position + Vector2.RIGHT.rotated(in_radians) * Globals.RADIUS):
				return false
	return true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
