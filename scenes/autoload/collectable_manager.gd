extends Node

@export var sand_scene: PackedScene

var all: Array[Collectable] = []

# Where drops are parented, handed over by GameWorld for the length of a run.
# Null between runs — nothing should be spawning then, and if something does it
# falls back to this autoload rather than erroring.
var _container: Node2D = null

func _ready() -> void:
	GameStateManager.register_resettable(self)

func bind_container(container: Node2D) -> void:
	_container = container

func reset() -> void:
	# Iterating a copy: Collectable._exit_tree() erases itself from `all` as it goes.
	for collectable in all.duplicate():
		if is_instance_valid(collectable):
			collectable.free()
	all.clear()

func spawn_sand(pos: Vector2, sand_amt: float) -> void:
	var sand: CollectableSand = sand_scene.instantiate()
	_drop_parent().add_child(sand)
	sand.setup(sand_amt)
	sand.global_position = pos
	# Same teleport-on-spawn as everything else placed after add_child; without this
	# the drop streaks in from world origin.
	sand.reset_physics_interpolation()
	all.append(sand)

func erase(collectable: Collectable) -> void:
	all.erase(collectable)

func _drop_parent() -> Node:
	if is_instance_valid(_container):
		return _container
	return self
