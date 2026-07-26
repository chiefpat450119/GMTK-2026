class_name MinionSpawner
extends Node

const spawn_radius := 800

@export var enemies_to_spawn: Array[PackedScene]

func spawn():
	for enemy in enemies_to_spawn:
		spawn_enemy(enemy)

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
	#if map size changes we might need to manually find these again );
	var left_border : float = -3200
	var right_border : float = 5200
	var top_border : float = -1400
	var bottom_border : float = 2800
	for i in range(10): #did loop instead of recursion because the debugger got mad at me
		var theta : float = randf_range(0,360) # By default enemies can spawn all around playe
		var offset = spawn_radius * Vector2.from_angle(deg_to_rad(theta))
		var spawn_pos = target_pos + offset
		if not (spawn_pos.x < left_border 
		or spawn_pos.x > right_border 
		or spawn_pos.y > bottom_border
		or spawn_pos.y < top_border): #no spawning outside for our enemies
			return spawn_pos
	return Vector2.ZERO #dont want it going forever, very unlikely
