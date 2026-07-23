extends Node

@export var health_component: HealthComponent # Player health component
@export var time_component: TimeComponent # Player time component
@export var time_bar: TextureProgressBar
@export var health_bar: ProgressBar
@export var time_listener: GameEventListener
@export var health_listener: GameEventListener

func _ready() -> void:
	time_listener.response.connect(_on_time_change)
	health_listener.response.connect(_on_health_change)
	# set initial fill
	_on_health_change()
	_on_time_change()     
	
func _on_health_change() -> void:
	health_bar.max_value = health_component.max_hp.current_val()
	health_bar.value = health_component.hp
	
func _on_time_change() -> void:
	time_bar.max_value = time_component.max_time.current_val()
	time_bar.value = time_component.time_left
