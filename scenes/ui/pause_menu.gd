extends StateScreen
## Pause overlay. Escape is handled by GameStateManager, not here — this screen
## only offers the buttons, so pausing works identically whether it came from the
## key or from a menu.

@export var resume_button: Button
@export var quit_button: Button


func _ready() -> void:
	super()
	resume_button.pressed.connect(GameStateManager.instance.resume)
	# Quit means quit the run, not the game: it drops the world and goes back to
	# the title, where Play starts a clean run.
	quit_button.pressed.connect(GameStateManager.instance.to_main_menu)
