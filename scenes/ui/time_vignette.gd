class_name TimeVignette
extends ColorRect
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

@export_group("Boss lull")
@export var lull_start_event: GameEventListener
@export var lull_end_event: GameEventListener
@export var lull_hz: float = 1.0
## Where the ring rests between beats, and where each beat lands. Keep the floor
## above ~0.6: the shader closes the radius from radius_weak to radius_full across
## this range, and under that the ring has barely left the corners, so the beat
## swings out of nothing instead of moving something already on screen.
@export_range(0.0, 1.0) var lull_intensity: float = 0.72
@export_range(0.0, 1.0) var lull_peak: float = 1.0
@export_range(0.02, 0.5) var lull_attack: float = 0.06
@export var lull_sfx: StringName = &"heart_beat"
@export var lull_timeout: float = 8.0

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
var _lull_time: float = -1.0
var _beats_fired: int = 0
var _death_tween: Tween
@onready var _material: ShaderMaterial = _own_material()
@onready var _base_tint: Color = _material.get_shader_parameter("tint")


func _ready() -> void:
	_clear()
	GameStateManager.instance.state_changed.connect(_on_state_changed)
	if lull_start_event != null:
		lull_start_event.response.connect(_start_lull)
	if lull_end_event != null:
		lull_end_event.response.connect(_end_lull)


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
	# Ticked before the target so the first heartbeat lands on the frame the wave
	# ends rather than a beat into the lull.
	var in_lull := _tick_lull(delta)

	var target := _read_target()
	if in_lull:
		target = maxf(target, lull_intensity)
	# Exponential ease, so the rate is the same whatever the framerate. Mostly
	# this matters for damage, which drops the clock in one step.
	_current = lerpf(_current, target, 1.0 - exp(-response * delta))

	if _current < OFF_EPSILON and target <= 0.0:
		_clear()
		return

	visible = true
	if in_lull:
		var swell := maxf(lull_peak, _current)
		_apply(lerpf(_current, swell, _lull_beat()), 1.0)
		return

	_phase = fmod(_phase + delta * lerpf(pulse_hz_min, pulse_hz_max, _current) * TAU, TAU)
	var beat := 0.5 - 0.5 * cos(_phase)
	var depth := pulse_depth * _current
	_apply(_current, lerpf(1.0 - depth, 1.0, beat))


func _start_lull() -> void:
	_lull_time = 0.0
	_beats_fired = 0


func _end_lull() -> void:
	_lull_time = -1.0
	_beats_fired = 0


func _tick_lull(delta: float) -> bool:
	if _lull_time < 0.0:
		return false

	var due := floori(_lull_time * lull_hz) + 1
	if due > _beats_fired:
		_beats_fired = due
		SFX.play(lull_sfx)

	_lull_time += delta
	if _lull_time >= lull_timeout:
		_end_lull()
		return false
	return true


func _lull_beat() -> float:
	var u := fmod(_lull_time * lull_hz, 1.0)
	if u < lull_attack:
		return u / lull_attack
	# Squared rather than cubed, so it settles onto the floor across most of the beat
	# instead of dropping there in the first third and sitting still.
	return pow(1.0 - (u - lull_attack) / (1.0 - lull_attack), 2.0)


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
	# A run that ends mid-lull — dying to the wave that spawns the boss — must not
	# hand the beat to the next one. The tree is paused for GAME_OVER, so nothing
	# ticks it in the meantime either.
	_end_lull()
	_material.set_shader_parameter("tint", _base_tint)
	_current = 0.0
	# Reset so the next time the player drops low the pulse opens on the swing up
	# rather than wherever the last one happened to stop.
	_phase = 0.0
	_apply(0.0, 1.0)
	visible = false


# The clock's beat rides on the opacity alone. Folded into the intensity it would
# drag the ring's radius along with it, and a vignette that inflates and deflates
# reads as the screen breathing rather than as a warning. The boss lull is the
# exception and passes its beat through `value` — see _process.
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
