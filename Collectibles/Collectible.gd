extends Node2D
class_name Collectible

var active = true
var timer : Timer
const TIMER_TIMEOUT = 10

func _init(graph : MyGraph, other_collectibles : Dictionary) -> void:
	var placing = graph.get_random_node()
	while other_collectibles.has(placing):
		placing = graph.get_random_node()
	other_collectibles[placing] = self
	position = placing.position

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(func(): active = true)

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT 
		and get_global_mouse_position().distance_to(position) <= Globals.RADIUS
		and event.is_pressed()):
		_on_collected()

func _process(_delta: float) -> void:
	queue_redraw()

func _on_collected() -> bool:
	if active:
		active = false
		timer.start(TIMER_TIMEOUT)
		return true
	return false
