class_name EnemySpawner
extends Node

# Distance away from player to spawn enemy. 
# Should be off screen
const spawn_radius : float = 400.0

@export var enemy_scene_ref : PackedScene
@export var player : Player

# test spawn -- replace with custom spawning behavior
func _ready() -> void:
	for i in range(7):
		spawn(enemy_scene_ref)

func spawn(enemy_scene : PackedScene) -> Enemy:
	# instantiate enemy 
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("PackedScene must have an Enemy root node")
		return null
	
	# init enemy
	var pos := find_spawn_pos(player.get_global_position())
	add_child(enemy)
	enemy.position = pos
	
	return enemy


func find_spawn_pos(target_pos : Vector2) -> Vector2:
	randomize()
	var theta : float = 2.0 * PI * randf()
	var offset = spawn_radius * Vector2.from_angle(theta)
	return target_pos + offset
