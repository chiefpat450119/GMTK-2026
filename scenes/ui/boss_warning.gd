class_name BossWarning
extends Control
## One-shot banner that warns the boss is on its way.
##
## Raised a few waves ahead of the boss so the run has time to react, rather
## than at the spawn itself — by then the clock sequence is already the warning.
## Lives in the shell alongside the rest of the HUD, so it holds no reference to
## the world that raised the event.

## Seconds the line sits fully opaque before it starts fading.
const HOLD := 2.5
const FADE_IN := 0.6
const FADE_OUT := 1.2
## How far the line drifts up over its lifetime, in pixels.
const DRIFT := 40.0

@export var label: Label
@export var listener: GameEventListener

## Fade/scale sequence and the slow upward drift, kept apart because the drift
## runs for the whole announcement while the fades are three separate steps.
var _fade: Tween
var _drift: Tween
var _rest_position: Vector2


func _ready() -> void:
	_rest_position = label.position
	_hide_now()
	listener.response.connect(announce)
	GameStateManager.instance.state_changed.connect(_on_state_changed)


func announce() -> void:
	# Restarting mid-announcement would otherwise leave the old tweens fighting
	# the new ones over modulate and position.
	_stop_tweens()

	visible = true
	modulate = Color.TRANSPARENT
	label.position = _rest_position
	label.scale = Vector2(0.88, 0.88)

	_fade = create_tween()
	_fade.set_parallel(true)
	_fade.tween_property(self, "modulate", Color.WHITE, FADE_IN) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fade.tween_property(label, "scale", Vector2.ONE, FADE_IN) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Back to sequential: each of these becomes its own step, so the hold only
	# starts once the fade in and the scale punch have both landed.
	_fade.set_parallel(false)
	_fade.tween_interval(HOLD)
	_fade.tween_property(self, "modulate", Color.TRANSPARENT, FADE_OUT) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_fade.tween_callback(_hide_now)

	_drift = create_tween()
	_drift.tween_property(label, "position", Vector2(0, -DRIFT), FADE_IN + HOLD + FADE_OUT) \
		.as_relative() \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_state_changed(_from: int, to: int) -> void:
	# The banner outlives the run it was raised in, so anything that ends or
	# interrupts the run takes it down rather than letting it hang over a game
	# over screen or the menu.
	if to != GameStateManager.GameState.PLAYING \
		and to != GameStateManager.GameState.PAUSED \
		and to != GameStateManager.GameState.UPGRADING:
		_stop_tweens()
		_hide_now()


func _stop_tweens() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if _drift != null and _drift.is_valid():
		_drift.kill()


func _hide_now() -> void:
	visible = false
	modulate = Color.TRANSPARENT
