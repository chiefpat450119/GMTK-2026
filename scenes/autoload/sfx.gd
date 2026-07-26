extends Node
## Global sound effects. Autoloaded as `SFX`.
##
## One AudioStreamPlayer per SoundBank entry, built on boot and never freed, so a
## sound outlives whatever started it. That matters here specifically: a run is
## torn down with an immediate free() (game_state_manager.gd), and projectiles
## free themselves on impact — a player parented to either gets cut mid-sample.
##
## Overlap is the engine's job. Each player's max_polyphony comes from its entry,
## so there is no pool and no instance bookkeeping; retrigger_cooldown covers the
## one case polyphony can't, a held trigger starting a voice every frame and
## continuously evicting the oldest.
##
## Per-ID players mean every voice of a sound shares that node's volume, pitch and
## bus. Variation between voices comes from wrapping the stream in an
## AudioStreamRandomizer, which rolls per playback. The trade is that two voices
## of one sound can't be panned apart — if a sound ever needs that, give it a
## small pool of its own rather than changing this.

## Set as metadata on a BaseButton to keep it out of the automatic UI wiring.
const NO_UI_SFX := &"no_ui_sfx"

const UI_HOVER := &"ui_hover"
const UI_PRESS := &"ui_press"

@export var bank: SoundBank
## Plays UI_HOVER and UI_PRESS on every BaseButton that enters the tree, so menus
## don't each have to wire their own. Buttons carrying the NO_UI_SFX meta opt out.
@export var auto_wire_buttons: bool = true

var _players: Dictionary[StringName, AudioStreamPlayer] = {}
var _cooldown_ms: Dictionary[StringName, int] = {}
var _next_allowed_ms: Dictionary[StringName, int] = {}


func _ready() -> void:
	# In code rather than the .tscn, for the reason GameStateManager gives for its
	# own: the tree is paused for PAUSED, UPGRADING and GAME_OVER, and the pause
	# menu, the upgrade cards and the game over screen are exactly where the UI
	# sounds have to play. A paused AudioStreamPlayer is a silent one.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_players()
	if auto_wire_buttons:
		get_tree().node_added.connect(_on_node_added)


# --- playback ---

## Starts `id`. Does nothing if the bank has no such sound, or if it played
## within its retrigger cooldown. Fire-and-forget: the caller may be freed on the
## next line without cutting the sound.
func play(id: StringName) -> void:
	if id == &"":
		return
	var player: AudioStreamPlayer = _players.get(id)

	var now := Time.get_ticks_msec()
	if now < _next_allowed_ms.get(id, 0):
		return
	_next_allowed_ms[id] = now + _cooldown_ms.get(id, 0)
	player.play()


## Cuts every voice of `id`. For sustained sounds — a charge-up that has to end
## when the trigger comes up. One-shots don't need this.
func stop(id: StringName) -> void:
	var player: AudioStreamPlayer = _players.get(id)
	if player:
		player.stop()
		player.pitch_scale = 1.0


func is_playing(id: StringName) -> bool:
	var player: AudioStreamPlayer = _players.get(id)
	return player != null and player.playing


## Retunes `id`. Applies to every voice of that sound at once, since they share
## the node — meant for sustained single-voice sounds, not for varying one-shots
## (use an AudioStreamRandomizer on the entry for that).
func set_pitch(id: StringName, pitch: float) -> void:
	var player: AudioStreamPlayer = _players.get(id)
	if player:
		player.pitch_scale = maxf(pitch, 0.01)


# --- mixing ---

## `linear` is 0..1, as a volume slider reports it. Muting at the bottom rather
## than passing a -inf dB through, which some drivers dislike.
func set_bus_volume(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	var silent := linear <= 0.0005
	AudioServer.set_bus_mute(idx, silent)
	if not silent:
		AudioServer.set_bus_volume_db(idx, linear_to_db(minf(linear, 1.0)))


func get_bus_volume(bus: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return 0.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


# --- internals ---

func _build_players() -> void:
	if bank == null:
		push_error("SFX has no SoundBank assigned — nothing will play")
		return

	for entry in bank.entries:
		if entry == null or entry.stream == null:
			continue
		if entry.id == &"":
			push_error("SoundBank has an entry with no id; skipped")
			continue

		var player := AudioStreamPlayer.new()
		player.name = String(entry.id)
		player.stream = entry.stream
		player.bus = entry.bus
		player.volume_db = entry.volume_db
		player.max_polyphony = entry.max_polyphony
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)

		_players[entry.id] = player
		_cooldown_ms[entry.id] = roundi(entry.retrigger_cooldown * 1000.0)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.has_meta(NO_UI_SFX):
		return
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.pressed.connect(play.bind(UI_PRESS))


# A disabled button still reports the hover, but shouldn't sound like something
# is there to click.
func _on_button_hovered(button: BaseButton) -> void:
	if not button.disabled:
		play(UI_HOVER)
