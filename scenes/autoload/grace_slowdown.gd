class_name GraceSlowdown
extends Node
## Drops the game into slow motion for the death grace window, and muffles the
## mix with it — the same ease drives both, so the audio arrives and lifts on
## exactly the clock the picture does.

@export_range(0.1, 1.0, 0.01) var grace_scale: float = 0.7
@export var ease_in: float = 0.18
@export var ease_out: float = 0.1

@export_group("Muffle")
## Master low-pass cutoff at full grace. Rolling off the top is what reads as
## "muted" — the mix loses its edge without losing its shape.
@export_range(200.0, 20500.0, 10.0) var muffle_cutoff_hz: float = 700.0
## How far the whole mix drops at full grace.
@export var muffle_db: float = -6.0

# An open low-pass, i.e. one that passes everything a mix can hold.
const _OPEN_CUTOFF := 20500.0
const _SETTLE := 3.0
const _SNAP_EPSILON := 0.002

# 0 while the game runs normally, 1 at full grace. Kept as the blend rather than
# as the time scale itself so the muffle still runs when grace_scale is 1.0 (no
# slowdown asked for, but the mix should still duck).
var _blend: float = 0.0
var _master_idx: int = -1
var _lowpass: AudioEffectLowPassFilter
var _amplify: AudioEffectAmplify
var _muffling: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 1.0
	_install_muffle()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	_remove_muffle()


func _process(delta: float) -> void:
	var slowing := _should_slow()
	var target := 1.0 if slowing else 0.0
	var duration := ease_in if slowing else ease_out

	# delta is itself scaled by Engine.time_scale, so the ease has to run on real
	# seconds — on scaled ones the approach slows down as it succeeds, and the
	# slowdown takes longer to arrive the deeper it goes.
	var real_delta := delta / maxf(Engine.time_scale, 0.01)

	if duration <= 0.0:
		_blend = target
	else:
		_blend = lerpf(_blend, target, 1.0 - exp(-real_delta / duration * _SETTLE))
	if absf(_blend - target) < _SNAP_EPSILON:
		_blend = target

	Engine.time_scale = lerpf(1.0, grace_scale, _blend)
	_apply_muffle(_blend)


func _should_slow() -> bool:
	var manager := GameStateManager.instance
	if manager == null or manager.state != GameStateManager.GameState.PLAYING:
		return false
	if Player.instance == null:
		return false
	var clock := Player.instance.time_component
	return clock != null and clock.in_grace_period()


# --- muffle ---

# The effects go onto Master from code rather than into default_bus_layout.tres,
# because they belong to this node and to nothing else: in the layout they would
# sit on the mix permanently, and anyone opening the mixer would find a filter
# there with no owner. Master rather than SFX so the music and the UI duck too —
# "all the sounds" includes the ones that aren't gameplay's.
#
# Amplify rather than the bus volume for the level drop: bus volume is what a
# settings slider owns, and writing it here would either fight that slider or
# quietly overwrite whatever the player set.
func _install_muffle() -> void:
	_master_idx = AudioServer.get_bus_index(&"Master")
	if _master_idx < 0:
		push_error("GraceSlowdown found no Master bus — the mix won't muffle")
		return

	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = _OPEN_CUTOFF
	_amplify = AudioEffectAmplify.new()
	_amplify.volume_db = 0.0

	AudioServer.add_bus_effect(_master_idx, _lowpass)
	AudioServer.add_bus_effect(_master_idx, _amplify)
	_set_muffle_enabled(false)


func _apply_muffle(amount: float) -> void:
	if _lowpass == null:
		return

	# Idling at zero still costs a filter pass over every frame of audio, and a
	# nominally-open low-pass isn't perfectly transparent. Off is off.
	if amount <= 0.0:
		_set_muffle_enabled(false)
		return
	_set_muffle_enabled(true)

	# Geometric rather than linear, because pitch is logarithmic: a straight lerp
	# down from 20 kHz spends most of its travel where nothing is audible and
	# then shuts the mix in the last sliver of the sweep.
	_lowpass.cutoff_hz = _OPEN_CUTOFF * pow(muffle_cutoff_hz / _OPEN_CUTOFF, amount)
	_amplify.volume_db = muffle_db * amount


func _set_muffle_enabled(enabled: bool) -> void:
	if _muffling == enabled:
		return
	_muffling = enabled
	for effect in [_lowpass, _amplify]:
		var idx := _effect_index(effect)
		if idx >= 0:
			AudioServer.set_bus_effect_enabled(_master_idx, idx, enabled)


# AudioServer state is global and outlives this node, so leaving the effects
# behind would muffle whatever loads next at whatever depth the run ended on.
func _remove_muffle() -> void:
	for effect in [_amplify, _lowpass]:
		var idx := _effect_index(effect)
		if idx >= 0:
			AudioServer.remove_bus_effect(_master_idx, idx)
	_lowpass = null
	_amplify = null
	_muffling = false


# By identity rather than by a remembered index: anything else added to Master
# later — or removed — shifts the indices out from under a stored one.
func _effect_index(effect: AudioEffect) -> int:
	if effect == null or _master_idx < 0:
		return -1
	for i in AudioServer.get_bus_effect_count(_master_idx):
		if AudioServer.get_bus_effect(_master_idx, i) == effect:
			return i
	return -1
