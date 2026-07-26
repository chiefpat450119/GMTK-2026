extends Node
## The battle theme. A node in main.tscn, beside GameStateManager.
##
## Reacts to state_changed and nothing else, so no screen or menu has to remember
## to start or stop the track:
##   PLAYING    — running at full volume.
##   UPGRADING  — still running, ducked, so the cards read over a quieter mix.
##   PAUSED     — held at its playhead. Silent, and resumes where it left off.
##   everything else (MAIN_MENU, GAME_OVER, VICTORY, SELECTING_GUN) — stopped, so the next
##   run opens from the top of the track rather than halfway through the last one.
##
## Ducking moves this player's volume, never the Music bus: the bus is what a
## volume slider owns, and pulling it down here would either fight that slider or
## quietly overwrite the player's setting.
##
## PROCESS_MODE_ALWAYS for the reason SFX gives — the tree is paused for
## UPGRADING, and a paused AudioStreamPlayer is a silent one.

## The looping track. Its stream must have looping on (set in the .import), or it
## plays through once and stops.
@export var player: AudioStreamPlayer
## How far the track drops while the upgrade cards are up.
@export var duck_db: float = -12.0
## Seconds to cross into and out of the ducked level.
@export var fade_duration: float = 0.35

## The player's authored volume, so ducking is relative to whatever it is mixed at.
var _full_db: float = 0.0
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_full_db = player.volume_db
	GameStateManager.instance.state_changed.connect(_on_state_changed)
	_apply(GameStateManager.instance.state)


func _on_state_changed(_from: int, to: int) -> void:
	_apply(to)


# --- internals ---

func _apply(state: int) -> void:
	var target_db := _full_db
	match state:
		GameStateManager.GameState.PLAYING:
			pass
		GameStateManager.GameState.UPGRADING:
			target_db += duck_db
		GameStateManager.GameState.PAUSED:
			player.stream_paused = true
			return
		_:
			_stop()
			return

	# Read before unpausing, and count a held player as running: `playing` reports
	# false while stream_paused is set, so testing it after the fact would take a
	# resume from the pause menu for a fresh start and restart the track.
	var running := player.playing or player.stream_paused
	player.stream_paused = false
	if not running:
		# Opening a run, not returning to one: start at the target level rather
		# than fading, so the first bar isn't a swell out of nothing.
		_cancel_fade()
		player.volume_db = target_db
		player.play()
		return
	_fade_to(target_db)


func _stop() -> void:
	_cancel_fade()
	player.stop()
	player.stream_paused = false
	player.volume_db = _full_db


func _fade_to(db: float) -> void:
	if is_equal_approx(player.volume_db, db):
		return
	_cancel_fade()
	# Bound to this node, so the fade keeps running while the tree is paused.
	_fade = create_tween()
	_fade.tween_property(player, "volume_db", db, fade_duration)


func _cancel_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = null
