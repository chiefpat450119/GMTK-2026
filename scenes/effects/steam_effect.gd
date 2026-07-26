class_name SteamEffect
extends Node2D

const TAIL_MARGIN := 0.2

## Multiplier on how many puffs each layer emits. Changing it restarts the emitters.
@export var intensity := 1.0:
	set = set_intensity
## Multiplied into every layer's colour, alpha included. White leaves the scene's own alone.
@export var tint := Color.WHITE:
	set = set_tint
## Sideways push in px/s², added to the buoyancy each layer already carries.
@export var wind := Vector2.ZERO:
	set = set_wind
## Emit one burst and stop, rather than venting continuously.
@export var one_shot := false
## How much of a one-shot burst escapes at once. Unused while venting.
@export_range(0.0, 1.0) var burst_explosiveness := 0.6
## Free the plume once a one-shot burst has fully died.
@export var free_when_finished := true
## Begin emitting as soon as the plume enters the tree.
@export var autostart := true

var _layers: Array[CPUParticles2D] = []
# What the scene authored. intensity, tint and wind apply against these so setting one
# twice doesn't compound onto what the last call left behind.
var _base_amounts: Array[int] = []
var _base_gravity: Array[Vector2] = []
var _base_colors: Array[Color] = []


func _ready() -> void:
	for child in get_children():
		if child is CPUParticles2D:
			var layer := child as CPUParticles2D
			_layers.append(layer)
			_base_amounts.append(layer.amount)
			_base_gravity.append(layer.gravity)
			_base_colors.append(layer.self_modulate)
			layer.emitting = false
			layer.one_shot = one_shot
			if one_shot:
				layer.explosiveness = burst_explosiveness

	_apply_intensity()
	_apply_wind()
	_apply_tint()

	# Physics interpolation is on project-wide, so without this a plume spawned away from
	# the origin spends its first frame streaking in from wherever it was created.
	reset_physics_interpolation()

	if autostart:
		start()


## Start venting, or fire the burst if this plume is one-shot. Safe to call on a plume
## that is already going: a one-shot restarts, a vent carries on uninterrupted.
func start() -> void:
	for layer in _layers:
		if one_shot:
			layer.restart()
		else:
			layer.emitting = true

	if one_shot and free_when_finished:
		get_tree().create_timer(_burst_duration(), false).timeout.connect(_on_burst_finished)


## Stop emitting. Puffs already in the air finish rising and fade out normally; pass true
## to cut them dead instead.
func stop(clear := false) -> void:
	for layer in _layers:
		layer.emitting = false
		if clear:
			layer.restart()
			layer.emitting = false


func set_intensity(value: float) -> void:
	intensity = maxf(value, 0.0)
	_apply_intensity()


func set_tint(value: Color) -> void:
	tint = value
	_apply_tint()


func set_wind(value: Vector2) -> void:
	wind = value
	_apply_wind()


func _apply_intensity() -> void:
	for i in _layers.size():
		_layers[i].amount = maxi(1, ceili(_base_amounts[i] * intensity))


# self_modulate multiplies the colour the ramps already produced instead of feeding into
# it, so the per-layer fades keep their shape, and it leaves the root's modulate free for
# a caller tweening the whole plume out. A shader uniform can't be used: the layers'
# materials are shared across every instance of this scene.
func _apply_tint() -> void:
	for i in _layers.size():
		_layers[i].self_modulate = _base_colors[i] * tint


func _apply_wind() -> void:
	for i in _layers.size():
		_layers[i].gravity = _base_gravity[i] + wind


# Timed rather than waiting on the emitters: a one-shot layer spreads its particles
# across a lifetime unless fully explosive, so freeing on the first quiet layer would cut
# the rest off mid-air.
func _burst_duration() -> float:
	var longest := 0.0
	for layer in _layers:
		var emit_window := layer.lifetime * (1.0 - layer.explosiveness)
		var tail := layer.lifetime * (1.0 + layer.lifetime_randomness)
		var speed := maxf(layer.speed_scale, 0.01)
		longest = maxf(longest, (emit_window + tail) / speed)
	return longest + TAIL_MARGIN


func _on_burst_finished() -> void:
	queue_free()
