extends StateScreen
## Title screen. Up while the game sits in MAIN_MENU, which is also the state it
## boots into.

@export var play_button: Button
@export var quit_button: Button


func _ready() -> void:
	super()
	play_button.pressed.connect(GameStateManager.start_run)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_quit_pressed() -> void:
	get_tree().quit()
