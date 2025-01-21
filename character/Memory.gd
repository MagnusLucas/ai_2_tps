extends Node
class_name Memory

var last_seen_ammo : Vector2
var last_seen_armor : Vector2
var last_seen_healing : Vector2

var engaged_enemy
var seen_enemies : Array[Vector2]

var currently_followed_path : Array[Vector2]
var attacking_enemies : Array[Vector2] = []
