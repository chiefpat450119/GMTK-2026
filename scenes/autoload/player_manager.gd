extends Node

@export var max_health: int = 100
@export var max_time: float = 120.0
@export var time_drain_per_second: float = 1.0

var health: int = 0
var time_left: float = 0.0
var default_time_drain_per_second: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = max_health
	time_left = max_time
	default_time_drain_per_second = time_drain_per_second


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
	remove_time(time_drain_per_second * delta)
	print(time_left)