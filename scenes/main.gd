extends Node
## The shell. Loaded once at boot and never freed.
##
## It owns three things and no gameplay: `GameStateManager`, `World`, the mount
## that manager instances each run under, and `UI`, the CanvasLayer every menu
## lives on.
## UI is PROCESS_MODE_ALWAYS so its children keep running while the tree is
## paused — otherwise the pause menu would freeze along with the game behind it.
##
## Nothing starts a run from here. The game boots into MAIN_MENU and the title
## screen's Play button is what calls start_run().

@export var world_mount: Node


func _ready() -> void:
	GameStateManager.instance.bind_shell(world_mount)
