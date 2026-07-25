extends Node

@export var sand_scene: PackedScene

var all: Array[Collectable] = []

func spawn_sand(pos: Vector2, sand_amt: float) -> void:
	var sand: CollectableSand = sand_scene.instantiate()
	sand.setup(sand_amt)
	sand.global_position = pos
	add_child(sand)
	all.append(sand)

func erase(collectable: Collectable) -> void:
	all.erase(collectable)
