extends Node
## The shell. Loaded once at boot and never freed.
##
## It owns two things and no gameplay: `World`, the mount GameStateManager
## instances each run under, and `UI`, the CanvasLayer every menu lives on.
## UI is PROCESS_MODE_ALWAYS so its children keep running while the tree is
## paused — otherwise the pause menu would freeze along with the game behind it.

@export var world_mount: Node


func _ready() -> void:
	GameStateManager.bind_shell(world_mount)
	# TEMPORARY: nothing else calls start_run() yet, so the game would sit in
	# MAIN_MENU — which means paused — with no menu on screen to leave it.
	# Delete this when the main menu's Play button lands.
	GameStateManager.start_run()
