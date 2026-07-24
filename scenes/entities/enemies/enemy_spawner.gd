class_name EnemySpawner
extends Node

# Distance away from player to spawn enemy. 
# Should be off screen
const spawn_radius : float = 400.0

@export var enemy_scene_ref : PackedScene

@export var enemy_pool : Array[EnemySpawnData]


# test spawn -- replace with custom spawning behavior
#func _ready() -> void:
	#
	#spawn_wave(40)


func spawn_wave(budget: int):
	var enemies : Array[EnemySpawnData] = enemy_budget_breakdown(budget)
	
	for enemy in enemies:
		spawn(enemy.enemy_scene)
		print("SPAWNING ENEMY WITH RATING: ", enemy.difficulty_rating)

func spawn(enemy_scene: PackedScene) -> Enemy:
	# instantiate enemy 
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("PackedScene must have an Enemy root node")
		return null
	
	# init enemy
	var pos := find_spawn_pos(Player.instance.get_global_position())
	add_child(enemy)
	enemy.position = pos
	
	return enemy


func find_spawn_pos(target_pos: Vector2) -> Vector2:
	randomize()
	var theta : float = 2.0 * PI * randf()
	var offset = spawn_radius * Vector2.from_angle(theta)
	return target_pos + offset


# returns array of EnemySpawnData by randomly assigning the ratings within the budget
# idk just read the code bro
func enemy_budget_breakdown(budget: int) -> Array[EnemySpawnData]:
	var breakdown : Array[EnemySpawnData] = []
	while budget > 0:
		var avail := enemy_pool.filter(func(elem: EnemySpawnData) -> bool:
			return elem.difficulty_rating <= budget)
		
		if avail.is_empty():
			break
		
		var picked : EnemySpawnData = avail.pick_random()
		breakdown.append(picked)
		budget -= picked.difficulty_rating
	
	return breakdown
