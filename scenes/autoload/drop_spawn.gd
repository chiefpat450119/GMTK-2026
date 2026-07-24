extends Node2D
#feel free to move this code/functionality, this was made before enemies exist
#so I hope it works, right now we only have sand

@export var sand_scene: PackedScene
	
#spawns collectable sand on spawn_node
func spawn_sand(spawn_node: Node2D):
	var sand: Area2D = sand_scene.instantiate()
	sand.global_position = spawn_node.global_position
	add_child(sand)
	
