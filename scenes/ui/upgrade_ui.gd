class_name UpgradeUI
extends CanvasLayer
## Modal upgrade screen.
##
## Split in two on purpose: *whether* it is up follows GameStateManager's
## UPGRADING state, *what* it shows follows the offer event. It never touches
## get_tree().paused — the manager owns that flag, and a screen that unpaused on
## its own would leave the manager believing the game was still frozen, so the
## next Escape would resume into an already-running game.
##
## The root's process_mode must stay ALWAYS or the cards go dead while paused.

@export var manager: UpgradeManager
@export var offer_listener: GameEventListener
@export var card_row: HBoxContainer
## Seconds the cards spend zooming in before a click on one counts. The screen
## appears under a cursor that was aiming at the game a frame ago, so without
## this the shot that earned the level-up picks the upgrade too.
@export var intro_duration: float = 1.0

var _cards: Array[CardUI] = []
var _rest_scale: Vector2
var _intro_tween: Tween


func _ready() -> void:
	for child in card_row.get_children():
		var card := child as CardUI
		if card:
			card.selected.connect(_on_card_selected)
			_cards.append(card)
	# The row is authored at its resting scale, so the intro is defined as a zoom
	# up to whatever the scene says rather than to a number duplicated in here.
	_rest_scale = card_row.scale
	offer_listener.response.connect(_on_offer)
	GameStateManager.state_changed.connect(_on_state_changed)
	hide()


func _on_state_changed(_from: int, _to: int) -> void:
	# Anything that leaves UPGRADING takes the cards down — including a Retry or a
	# quit-to-menu triggered from somewhere this screen knows nothing about.
	if GameStateManager.state != GameStateManager.GameState.UPGRADING:
		_close()


func _on_offer() -> void:
	# Ignore a second offer raised while the screen is already up.
	if visible:
		return
	var picks := _roll()
	if picks.is_empty():
		# Pool is dry, or misconfigured. Hand the state back rather than leaving
		# the game paused behind a screen that will never show anything.
		GameStateManager.close_upgrades()
		return
	# Fewer picks than card slots once the pool runs low.
	for i in _cards.size():
		if i < picks.size():
			_cards[i].setup(picks[i])
			_cards[i].show()
		else:
			_cards[i].hide()
	show()
	_play_intro()


# Grows the row from a point at its own centre — card_row's pivot is already set
# to the middle of its rect — and only opens the cards to clicks once it lands.
func _play_intro() -> void:
	_set_cards_clickable(false)
	if _intro_tween:
		_intro_tween.kill()

	card_row.scale = Vector2.ZERO
	_intro_tween = create_tween()
	# The whole point of this screen is that the game behind it is frozen, so the
	# tween has to be explicitly exempt from the pause rather than inherit it.
	_intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_intro_tween.tween_property(card_row, "scale", _rest_scale, intro_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_callback(_set_cards_clickable.bind(true))


# CardUI reads its click in _gui_input on its own root, so muting that root is
# what makes a card inert — no second "are we accepting yet" flag to drift from.
func _set_cards_clickable(clickable: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	for card in _cards:
		card.mouse_filter = filter


func _close() -> void:
	if _intro_tween:
		_intro_tween.kill()
	# Restored so the next offer starts from a known scale even if it interrupted
	# an intro mid-flight.
	card_row.scale = _rest_scale
	hide()


func _roll() -> Array[Upgrade]:
	if manager == null:
		push_warning("UpgradeUI has no UpgradeManager assigned")
		return []
	return manager.roll(_cards.size())


func _on_card_selected(upgrade: Upgrade) -> void:
	manager.apply(upgrade)
	_close()
	GameStateManager.close_upgrades()
