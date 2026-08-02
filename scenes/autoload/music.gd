extends Node

@export var duck_db: float = -12.0
@export var fade_duration: float = 0.35

@export var wave_end_event: GameEventListener
@export var boss_event: GameEventListener

@export var battle_player: AudioStreamPlayer
@export var boss_player: AudioStreamPlayer
@export var menu_player: AudioStreamPlayer

var _active_player: AudioStreamPlayer
var _full_db: Dictionary[AudioStreamPlayer, float] = {}
var _fade: Tween
var _boss_active: bool = false

# --- Web-safe playback tracking ---
# stream_paused is unreliable on the HTML5 export: the browser's Web Audio API
# can report .playing as false mid-stream, and toggling stream_paused on a live
# node can trigger a restart. Instead we own the state entirely:
#   _is_playing  – true while we consider the player live (between play() and stop())
#   _saved_pos   – the position we stashed when we stopped so we can resume there
var _is_playing: Dictionary[AudioStreamPlayer, bool] = {}
var _saved_pos:  Dictionary[AudioStreamPlayer, float] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for p: AudioStreamPlayer in [battle_player, boss_player, menu_player]:
		_full_db[p]    = p.volume_db
		_is_playing[p] = false
		_saved_pos[p]  = 0.0

	_active_player = battle_player

	GameStateManager.instance.state_changed.connect(_on_state_changed)
	wave_end_event.response.connect(_on_wave_end)
	boss_event.response.connect(_on_boss_start)

	_apply(GameStateManager.instance.state)


func _on_state_changed(_from: int, to: int) -> void:
	_apply(to)


func _on_wave_end() -> void:
	# The last wave before the boss has finished. Stop the battle track so there
	# is silence through the upgrade screen; the boss track will take over once
	# the boss spawns. We discard the saved position — the battle theme should
	# restart from the top if the track is ever needed again.
	_cancel_fade()

	if _active_player == battle_player:
		_active_player = null

	_is_playing[battle_player] = false
	_saved_pos[battle_player]  = 0.0
	battle_player.stop()
	battle_player.volume_db = _full_db[battle_player]


func _on_boss_start() -> void:
	_boss_active = true
	_apply(GameStateManager.instance.state)


func _switch_track(next_player: AudioStreamPlayer) -> void:
	if next_player == _active_player:
		return
	_cancel_fade()

	if _active_player != null:
		_stop_player(_active_player)
		_active_player.volume_db = _full_db[_active_player]

	_active_player = next_player

func _select_track(state: int) -> void:
	match state:
		GameStateManager.GameState.PLAYING, GameStateManager.GameState.UPGRADING:
			if _boss_active:
				_switch_track(boss_player)
			else:
				_switch_track(battle_player)

		GameStateManager.GameState.MAIN_MENU:
			_switch_track(menu_player)

		GameStateManager.GameState.PAUSED:
			# Keep the current track active.
			pass

		_:
			_active_player = null

func _apply(state: int) -> void:
	_select_track(state)
	match state:
		GameStateManager.GameState.PLAYING:
			_play_active(false)

		GameStateManager.GameState.UPGRADING:
			_play_active(true)

		GameStateManager.GameState.PAUSED:
			_pause_active()

		GameStateManager.GameState.MAIN_MENU:
			_stop_all()
			_play_active(false)

		_:
			_stop_all()

			# Every new run begins with the battle track selected.
			_switch_track(battle_player)
			_boss_active = false


func _play_active(ducked: bool) -> void:
	if _active_player == null:
		return

	var target_db: float = _full_db[_active_player]
	if ducked:
		target_db += duck_db

	# If the track is already live just adjust the volume — don't touch playback.
	if _is_playing[_active_player]:
		_fade_to(target_db)
		return

	# Not running: start (or resume) from the saved position.
	_cancel_fade()
	_active_player.volume_db = target_db
	_active_player.play(_saved_pos[_active_player])
	_is_playing[_active_player] = true


func _pause_active() -> void:
	if _active_player == null:
		return

	_cancel_fade()
	_stop_player(_active_player)


func _stop_all() -> void:
	_cancel_fade()

	for p: AudioStreamPlayer in [battle_player, boss_player, menu_player]:
		_stop_player(p)
		p.volume_db = _full_db[p]
		_saved_pos[p] = 0.0		# discard saved positions — this is a hard reset


# Saves the current playback position and stops the player.
# Use this instead of stream_paused everywhere so the position is always
# under our control and never depends on the browser's audio state.
func _stop_player(p: AudioStreamPlayer) -> void:
	if _is_playing[p]:
		_saved_pos[p] = p.get_playback_position()
	_is_playing[p] = false
	p.stop()


func _fade_to(db: float) -> void:
	if _active_player == null:
		return

	if is_equal_approx(_active_player.volume_db, db):
		return

	_cancel_fade()

	_fade = create_tween()
	_fade.tween_property(
		_active_player,
		"volume_db",
		db,
		fade_duration
	)


func _cancel_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()

	_fade = null
