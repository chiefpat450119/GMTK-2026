extends Node

@export var max_health: Stat
@export var max_time: Stat
@export var time_decay_scale: Stat

@onready var health := max_health.current_val()
@onready var time_left := max_time.current_val()


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#health = max_health.current_val()
	#time_left = max_time.current_val()


func add_health(amount: int) -> void:
	set_health(health + amount)


func remove_health(amount: int) -> void:
	set_health(health - amount)


func set_health(value: int) -> void:
	health = clamp(value, 0, max_health)


func add_time(amount: float) -> void:
	set_time(time_left + amount)


func remove_time(amount: float) -> void:
	set_time(time_left - amount)


func set_time(value: float) -> void:
	time_left = clamp(value, 0, max_time)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	remove_time(time_decay_scale.current_val() * delta)
	print(time_left)
