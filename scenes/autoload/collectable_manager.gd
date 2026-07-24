extends Node

@export var sand_scene: PackedScene

var all: Array[Collectable] = []

func spawn_sand(pos: Vector2) -> void:
	var sand: Collectable = sand_scene.instantiate()
	sand.global_position = pos
	add_child(sand)
	all.append(sand)

func erase(collectable: Collectable) -> void:
	all.erase(collectable)
