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
	# the title, where Play starts a clean run. Through the same fade Play uses, so
	# the world is torn down out of sight instead of vanishing under the menu.
	quit_button.pressed.connect(_on_quit_pressed)


func _on_quit_pressed() -> void:
	SceneTransition.instance.play(GameStateManager.instance.to_main_menu)
