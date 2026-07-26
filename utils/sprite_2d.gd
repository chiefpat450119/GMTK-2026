extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#ripped this out of gun select ui
	if GameStateManager.instance:
		GameStateManager.instance.state_changed.connect(_on_state_changed)
	hide()

func _on_state_changed(_from: int, _to: int) -> void:
	#only shows battle cursor when playing
	if GameStateManager.instance.state == GameStateManager.GameState.PLAYING:
		show_custom_cursor()
	else:
		regular_cursor()
		
#shows curser and hides menu cursor
func show_custom_cursor():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	show()
	
#hides curser and shows menu cursor
func regular_cursor():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hide()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#it is a good thing tutorials exist
	global_position = lerp(global_position, get_global_mouse_position(), 40*delta)
	
