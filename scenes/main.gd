extends Node
## The shell. Loaded once at boot and never freed.
##
## It owns two things and no gameplay: `World`, the mount GameStateManager
## instances each run under, and `UI`, the CanvasLayer every menu lives on.
## UI is PROCESS_MODE_ALWAYS so its children keep running while the tree is
## paused — otherwise the pause menu would freeze along with the game behind it.
##
## Nothing starts a run from here. The game boots into MAIN_MENU and the title
## screen's Play button is what calls start_run().

@export var world_mount: Node


func _ready() -> void:
	GameStateManager.bind_shell(world_mount)
