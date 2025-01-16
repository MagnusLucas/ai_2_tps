extends Node
class_name Memory

var last_seen_ammo : Vector2i
var last_seen_armor : Vector2i
var last_seen_healing : Vector2i

var engaged_enemy : Vector2i
var non_engaged_seen_enemies : Array[Vector2i]

var currently_followed_path : Array[Vector2i]
