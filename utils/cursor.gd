extends Node2D

@export var custom_cursor_img: CompressedTexture2D

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
	Input.set_custom_mouse_cursor(custom_cursor_img, Input.CURSOR_ARROW, custom_cursor_img.get_size() / 2)
	
#hides curser and shows menu cursor
func regular_cursor():
	Input.set_custom_mouse_cursor(null)	
