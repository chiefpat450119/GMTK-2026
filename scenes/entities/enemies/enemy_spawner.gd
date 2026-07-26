class_name EnemySpawner
extends Node

# Distance away from player to spawn enemy. 
# Should be off screen
const spawn_radius: float = 1000.0

@export var wave_timer: Timer
@export var wave_changed_event : GameEvent
@export var enemy_pool: Array[EnemySpawnData]

@onready var budget: int = 5

func begin_waves():
	spawn_wave()
	wave_timer.start()
	wave_timer.timeout.connect(spawn_wave)


func spawn_wave():
	var enemies : Array[EnemySpawnData] = enemy_budget_breakdown(budget)
	var msg := "BUDGET: " + str(budget) + ", RATINGS: ["
	for enemy in enemies:
		spawn_enemy(enemy.enemy_scene)
		msg += str(enemy.difficulty_rating) + ","
	msg += "]"
	print(msg)
	increase_budget()
	wave_changed_event.raise()


#TODO: not this
func increase_budget():
	budget += 1


func spawn_enemy(enemy_scene: PackedScene) -> Enemy:
	# instantiate enemy 
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		push_error("PackedScene must have an Enemy root node")
		return null
	
	# init enemy
	var pos := find_spawn_pos(Player.instance.get_global_position())
	add_child(enemy)
	enemy.position = pos
	# Spawned at the origin and moved here, which physics interpolation would render
	# as the enemy flying in from world origin at spawn_radius per tick.
	enemy.reset_physics_interpolation()

	return enemy


func find_spawn_pos(target_pos: Vector2) -> Vector2:
	randomize()
	# I literally just manually walked to the borders of the map and wrote down the numbers lol
	var left_border : float = -2800
	var right_border : float = 4800
	var top_border : float = -1200
	var bottom_border : float = 2600
	var theta : float = randf_range(0,360) # By default enemies can spawn all around player
	
	# If player can see the border, enemies won't spawn from that direction
	if Player.instance.global_position.x < left_border:
		theta = randf_range(-90,90)
	if Player.instance.global_position.x > right_border:
		theta = randf_range(90,270)
	if Player.instance.global_position.y > bottom_border:
		theta = randf_range(180,360)
	if Player.instance.global_position.y < top_border:
		theta = randf_range(0,180)

	var offset = spawn_radius * Vector2.from_angle(deg_to_rad(theta))
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
