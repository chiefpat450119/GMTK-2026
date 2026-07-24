# Timer that lives outside the scene tree; advance it yourself with tick(delta).

class_name Cooldown
extends RefCounted

var time_left: float = 0.0
var _duration: float
var _started: bool = false


func _init(duration: float) -> void:
	_duration = duration


## Arms the cooldown for its full duration. Call again to restart it.
func start() -> void:
	time_left = _duration
	_started = true


## Disarms the cooldown, returning it to the un-started state.
func stop() -> void:
	time_left = 0.0
	_started = false


## Advances the cooldown. No-op while un-started.
func tick(delta: float) -> void:
	if not _started:
		return
	time_left = maxf(time_left - delta, 0.0)


## True once start() has been called, until stop().
func is_started() -> bool:
	return _started


## True when an armed cooldown has run out. Stays true until stop() or start().
func is_done() -> bool:
	return _started and time_left <= 0.0
