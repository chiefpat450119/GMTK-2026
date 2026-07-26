extends StateScreen
## Shown when the run's clock hits zero.
##
## Retry goes through start_run() like a fresh run does, so the world is rebuilt
## and every run-scoped modifier is cleared — there is no shortcut that reuses
## the dead world.

@export var retry_button: Button
@export var menu_button: Button


func _ready() -> void:
	super()
	retry_button.pressed.connect(GameStateManager.instance.start_run)
	menu_button.pressed.connect(GameStateManager.instance.to_main_menu)
