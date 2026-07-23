extends Control

@export var play_button : Button

func _ready() -> void:
	play_button.connect("pressed", _on_play_button_pressed)

## Switch to main play scene
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
