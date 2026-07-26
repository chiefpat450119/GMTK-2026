class_name EnemySpawner
extends Node

# indexed by wave_count 
# tweak pls i pulled these numbers out of my ass
const BUDGET_TABLE: Array[int] = [
	8,
	10,
	12,
	14,
	16,
	20,
	24,
	26,
	27,
	28,
	30,
	31,
	33,
	35,
	38,
	40,
	41,
	42,
	43,
	44,
	45,
]

# when budget table surpassed, fallback to increase budget by this
const DEFAULT_BUDGET_SCALING: int = 2

# Distance away from player to spawn enemy. 
# Should be off screen
const spawn_radius: float = 1000.0

@export var wave_timer: Timer
@export var wave_changed_event : GameEvent
@export var enemy_pool: Array[EnemySpawnData]

@export var boss_spawner: PackedScene

@onready var budget: int = 5


@export var boss_spawn_wave: int = 20
var wave_counter: int = 0

@export var boss_start_event: GameEvent
@export var wave_end_event: GameEvent

var _wave_running = true

func begin_waves():
	wave_counter = 0
	_wave_running = true
	spawn_wave()
	
	if wave_timer:
		wave_timer.start()
		wave_timer.timeout.connect(spawn_wave)


func spawn_wave():
	if not _wave_running:
		return
	
	if wave_counter >= boss_spawn_wave: 
		spawn_boss()
		return
	
	var enemies : Array[EnemySpawnData] = enemy_budget_breakdown(budget)
	spawn_enemies(enemies)
	
	increase_budget(wave_counter)
	wave_counter += 1
	
	if wave_changed_event:
		wave_changed_event.raise()

func spawn_enemies(enemies: Array[EnemySpawnData]):
	var msg := "BUDGET: " + str(budget) + ", RATINGS: ["
	for enemy in enemies:
		spawn_enemy(enemy.enemy_scene)
		msg += str(enemy.difficulty_rating) + ","
	msg += "]"
	print(msg)


func increase_budget(wave_index: int):
	if wave_index >= BUDGET_TABLE.size():
		budget += 2 # default scaling
		return
	
	budget = BUDGET_TABLE[wave_index]

func spawn_boss():
	wave_end_event.raise()
	
	await get_tree().create_timer(5).timeout
	
	boss_start_event.raise()
	
	var instance: BossSpawner = boss_spawner.instantiate()
	get_parent().add_child(instance)
	instance.global_position = Player.instance.global_position
	
	_wave_running = false

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

# returns array of EnemySpawnData by randomly assigning the ratings within the budget
# idk just read the code bro
@warning_ignore("shadowed_variable")
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
