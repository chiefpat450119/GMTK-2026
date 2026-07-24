extends Node

@export var world_mount: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameStateManager.bind_shell(world_mount)
