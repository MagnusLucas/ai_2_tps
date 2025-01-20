extends Collectible
class_name Ammo

func _draw() -> void:
	const color = Color.DIM_GRAY
	if active:
		draw_circle(Vector2i.ZERO, Globals.RADIUS, color)
	else:
		draw_arc(Vector2i.ZERO, Globals.RADIUS, 0, 2*PI*timer.time_left/TIMER_TIMEOUT, 18, color)

func _on_collected(character : Character = null) -> bool:
	if character and active:
		character.ammo_supply = Character.MAX_AMMO_SUPPLY
	return super._on_collected()
