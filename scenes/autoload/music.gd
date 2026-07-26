extends Node

@export var duck_db: float = -12.0
@export var fade_duration: float = 0.35

@export var start_game_event: GameEventListener
@export var wave_end_event: GameEventListener
@export var boss_event: GameEventListener

@export var battle_player: AudioStreamPlayer
@export var boss_player: AudioStreamPlayer
@export var menu_player: AudioStreamPlayer

var _active_player: AudioStreamPlayer
var _full_db: Dictionary[AudioStreamPlayer, float] = {}
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_full_db[battle_player] = battle_player.volume_db
	_full_db[boss_player] = boss_player.volume_db
	_full_db[menu_player] = menu_player.volume_db

	_active_player = menu_player

	GameStateManager.instance.state_changed.connect(_on_state_changed)
	
	
	wave_end_event.response.connect(_on_wave_end)
	boss_event.response.connect(_on_boss_start)

	_apply(GameStateManager.instance.state)


func _on_state_changed(from: int, to: int) -> void:
	# Returning from the upgrade screen after a normal wave starts the battle
	# music again. A boss event can select boss_player before this happens.
	if (
		to == GameStateManager.GameState.PLAYING
		and from == GameStateManager.GameState.UPGRADING
		and _active_player == null
	):
		_active_player = battle_player

	_apply(to)


func _on_wave_end() -> void:
	_cancel_fade()

	battle_player.stop()
	battle_player.stream_paused = false
	battle_player.volume_db = _full_db[battle_player]

	if _active_player == battle_player:
		_active_player = null

func _on_game_start() -> void:
	_stop_all()
	_switch_track(battle_player)

func _on_boss_start() -> void:
	_switch_track(boss_player)

func _on_menu_start() -> void:
	_switch_track(menu_player)

func _switch_track(next_player: AudioStreamPlayer) -> void:
	_cancel_fade()

	if _active_player != null and _active_player != next_player:
		_active_player.stop()
		_active_player.stream_paused = false
		_active_player.volume_db = _full_db[_active_player]

	_active_player = next_player
	_apply(GameStateManager.instance.state)


func _apply(state: int) -> void:
	match state:
		GameStateManager.GameState.PLAYING:
			_play_active(false)

		GameStateManager.GameState.UPGRADING:
			_play_active(true)

		GameStateManager.GameState.PAUSED:
			if _active_player != null:
				_active_player.stream_paused = true
				
		GameStateManager.GameState.MAIN_MENU:
			_play_active(false)

		_:
			_stop_all()

			# Every new run begins with the battle track selected.
			_active_player = battle_player


func _play_active(ducked: bool) -> void:
	if _active_player == null:
		return

	var target_db: float = _full_db[_active_player]

	if ducked:
		target_db += duck_db

	var running := (
		_active_player.playing
		or _active_player.stream_paused
	)

	_active_player.stream_paused = false

	if not running:
		_cancel_fade()
		_active_player.volume_db = target_db
		_active_player.play()
		return

	_fade_to(target_db)


func _stop_all() -> void:
	_cancel_fade()

	for music_player: AudioStreamPlayer in [battle_player, boss_player]:
		music_player.stop()
		music_player.stream_paused = false
		music_player.volume_db = _full_db[music_player]


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
