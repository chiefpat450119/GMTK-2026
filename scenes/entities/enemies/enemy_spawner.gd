class_name EnemySpawner
extends Node

# Distance away from player to spawn enemy. 
# Should be off screen
const spawn_radius: float = 400.0

@export var enemy_scene_ref: PackedScene
@export var wave_timer: Timer
@export var wave_changed_event : GameEvent

@export var enemy_pool: Array[EnemySpawnData]

@onready var budget: int = 10


# test spawn -- replace with custom spawning behavior
func _ready() -> void:
	
	begin_waves()

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
	budget += 5


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
