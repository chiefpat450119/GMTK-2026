extends Node

@export var time_component: TimeComponent # Player time component
@export var time_bar: TextureProgressBar
@export var time_listener: GameEventListener

func _ready() -> void:
	time_listener.response.connect(_on_time_change)
	# set initial fill
	call_deferred("_on_time_change")
	
func _on_time_change() -> void:
	time_bar.max_value = time_component.max_time.current_val()
	time_bar.value = time_component.time_left
