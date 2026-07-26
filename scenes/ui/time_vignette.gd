class_name TimeVignette
extends ColorRect
## Screen-edge vignette that closes in as the run clock empties.
##
## Silent above `appear_at` of the player's max time, at its worst at or below
## `full_at`, and beating faster the closer the run is to ending.
##
## Reads the clock straight off Player.instance every frame rather than through
## the time-changed event: the ease and the pulse need a per-frame tick anyway,
## and polling means the effect clears itself when the player is freed between
## runs instead of waiting for an event that will never come.

# Under this the effect is switched off outright, which also drops the
# full-screen pass and the screen copy the shader reads.
const OFF_EPSILON := 0.001

## Fraction of max time at which the vignette starts to show.
@export_range(0.0, 1.0) var appear_at: float = 0.20
## Fraction at or below which it is fully exaggerated.
@export_range(0.0, 1.0) var full_at: float = 0.05
## How fast the drawn intensity chases the clock. Higher snaps harder to a hit.
@export var response: float = 12.0
## Pulse rate at `appear_at` and at `full_at`, in beats per second.
@export var pulse_hz_min: float = 0.7
@export var pulse_hz_max: float = 2.0
## Share of the opacity the pulse swings once the vignette is at its worst. It
## fades in with the intensity, so the effect arrives steady and only starts
## breathing as the clock actually runs out. 0 for no pulse at all.
@export_range(0.0, 1.0) var pulse_depth: float = 0.12
## Ease-out on the appear_at..full_at ramp. The warning wants to be legible well
## before the clock is critical, so the front of the range is worth more than
## the back: at 4.0 the vignette is ~80% up a third of the way in and spends the
## rest of the run creeping to full. 1.0 for the plain linear ramp.
@export_range(1.0, 8.0) var ramp: float = 4.0

@export_group("Death")
## What the ring's tint bleeds to once the run is over. Multiplied over the
## screen, so this reads as how much colour the edges keep — the default is the
## same luminance as the red it starts from, just neutral, which drains the
## warning out of the effect without the corners visibly lifting or dropping.
@export var death_tint: Color = Color(0.25, 0.25, 0.26, 1.0)
## Seconds to bleed across. Runs long on purpose: it should settle about as the
## game over screen's buttons finish sliding in, not race the gears.
@export var death_fade: float = 1.0

var _current: float = 0.0
var _phase: float = 0.0
var _death_tween: Tween
@onready var _material: ShaderMaterial = _own_material()
@onready var _base_tint: Color = _material.get_shader_parameter("tint")


func _ready() -> void:
	_clear()
	GameStateManager.instance.state_changed.connect(_on_state_changed)


# The tree is paused for GAME_OVER and VICTORY, so the ring freezes exactly where
# the run left it and holds under the screen — which is the point. Clearing has to
# be explicit: everything a retry passes through is paused as well, so the ease in
# _process wouldn't get a frame until the next run was already being played.
#
# Only GAME_OVER bleeds out: the red going out of the edges reads as the clock
# finishing you off, which is not what a win is.
func _on_state_changed(from: int, to: int) -> void:
	if to == GameStateManager.GameState.GAME_OVER:
		_bleed_out()
	elif from == GameStateManager.GameState.GAME_OVER \
			or from == GameStateManager.GameState.VICTORY:
		_clear()


# The intensity is already frozen by the pause, so this is the one thing still
# moving under the screen: the red goes out of the edges while everything else
# holds. TWEEN_PAUSE_PROCESS because the tree is paused for the whole of
# GAME_OVER — bound to a pausable node, the tween would otherwise sit still too.
func _bleed_out() -> void:
	_kill_death_tween()
	# Nothing on screen to bleed. Skipped rather than tweened invisibly, so a
	# death that lands with the vignette down doesn't leave the tint parked on
	# grey for the next run.
	if not visible:
		return
	_death_tween = create_tween()
	_death_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_death_tween.tween_property(_material, "shader_parameter/tint", death_tint, death_fade) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _kill_death_tween() -> void:
	if _death_tween and _death_tween.is_valid():
		_death_tween.kill()
	_death_tween = null


func _process(delta: float) -> void:
	var target := _read_target()
	# Exponential ease, so the rate is the same whatever the framerate. Mostly
	# this matters for damage, which drops the clock in one step.
	_current = lerpf(_current, target, 1.0 - exp(-response * delta))

	if _current < OFF_EPSILON and target <= 0.0:
		_clear()
		return

	visible = true
	_phase = fmod(_phase + delta * lerpf(pulse_hz_min, pulse_hz_max, _current) * TAU, TAU)
	var beat := 0.5 - 0.5 * cos(_phase)
	var depth := pulse_depth * _current
	_apply(_current, lerpf(1.0 - depth, 1.0, beat))


# Maps time remaining onto 0..1. Inverted because the effect grows as the clock
# shrinks: appear_at reads 0 and full_at reads 1. Eased so the ramp still starts
# from nothing at appear_at rather than popping in at half strength.
func _read_target() -> float:
	if Player.instance == null:
		return 0.0
	var clock := Player.instance.time_component
	if clock == null:
		return 0.0
	var t := clampf(inverse_lerp(appear_at, full_at, clock.time_percentage()), 0.0, 1.0)
	return 1.0 - pow(1.0 - t, ramp)


func _clear() -> void:
	_kill_death_tween()
	_material.set_shader_parameter("tint", _base_tint)
	_current = 0.0
	# Reset so the next time the player drops low the pulse opens on the swing up
	# rather than wherever the last one happened to stop.
	_phase = 0.0
	_apply(0.0, 1.0)
	visible = false


# The beat rides on the opacity alone. Folded into the intensity it would drag
# the ring's radius along with it, and a vignette that inflates and deflates
# reads as the screen breathing rather than as a warning.
func _apply(value: float, beat: float) -> void:
	_material.set_shader_parameter("intensity", value)
	_material.set_shader_parameter("pulse", beat)


# The material is a scene sub-resource, so every instance of this scene shares
# one copy. Left shared, two vignettes would fight over the same intensity, and
# whatever the last one wrote would be saved back into the scene file.
func _own_material() -> ShaderMaterial:
	var owned := (material as ShaderMaterial).duplicate() as ShaderMaterial
	material = owned
	return owned
