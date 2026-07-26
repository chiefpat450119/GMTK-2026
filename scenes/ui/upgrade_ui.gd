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
@export var dim: ColorRect
## Seconds the backdrop takes to darken. Shorter than the cards take to arrive, so
## the game is already reading as "stopped" by the time they land.
@export var dim_fade_duration: float = 0.25
## Seconds one card spends rising into place.
@export var card_rise_duration: float = 0.45
## Seconds between one card setting off and the next. Cards arriving together read
## as one object sliding in; a gap between them is what makes them three separate
## things to choose from.
@export var card_stagger: float = 0.08

var _cards: Array[CardUI] = []
# Where each card's offset transform rests. Read from the scene so the rise ends
# on what the scene says rather than on a zero this script would be assuming, and
# so it agrees with the ButtonFeedback on the card, which takes its own resting
# pose from the same place.
var _card_rest_offsets: Array[Vector2] = []
var _intro_tween: Tween


func _ready() -> void:
	for child in card_row.get_children():
		var card := child as CardUI
		if card:
			card.selected.connect(_on_card_selected)
			# The rise rides the offset transform, which does nothing until it is
			# switched on. Cards carrying a ButtonFeedback have it on already; this
			# is for the ones that don't.
			card.offset_transform_enabled = true
			_cards.append(card)
			_card_rest_offsets.append(card.offset_transform_position)
	offer_listener.response.connect(_on_offer)
	GameStateManager.instance.state_changed.connect(_on_state_changed)
	hide()


func _on_state_changed(_from: int, _to: int) -> void:
	# Anything that leaves SELECTING_GUN takes the cards down — including a Retry or a
	# quit-to-menu triggered from somewhere this screen knows nothing about.
	if GameStateManager.instance.state != GameStateManager.GameState.SELECTING_GUN:
		_close()


func _on_offer() -> void:
	# Queued offers arrive from close_upgrades(), i.e. only after _close() has
	# already hidden the previous set. A raise while the cards are still up is
	# something else entirely — the debug harness — and gets ignored.
	if visible:
		return
	var picks := _roll()
	if picks.is_empty():
		# Pool is dry, or misconfigured. Hand the state back rather than leaving
		# the game paused behind a screen that will never show anything.
		GameStateManager.instance.cancel_upgrades()
		push_warning("Uprade picks empty")
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


# Darkens the backdrop and deals the cards in from under the bottom edge, one
# after another, then opens them to clicks once the last one lands.
#
# One tween drives the whole screen. The stagger is a delay per card rather than a
# chain of callbacks, so every part shares a clock and killing the tween on an
# interrupted intro can't leave a queued callback to fire into a closed screen.
func _play_intro() -> void:
	_set_cards_clickable(false)
	if _intro_tween:
		_intro_tween.kill()

	_intro_tween = create_tween()
	# The whole point of this screen is that the game behind it is frozen, so the
	# tween has to be explicitly exempt from the pause rather than inherit it.
	_intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_intro_tween.set_parallel(true)

	if dim:
		# modulate rather than the colour itself, so the authored opacity stays the
		# thing that decides how dark "dim" is.
		dim.modulate.a = 0.0
		_intro_tween.tween_property(dim, "modulate:a", 1.0, dim_fade_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var risers := _shown_cards()
	for i in risers.size():
		var card: CardUI = risers[i]
		var rest: Vector2 = _card_rest_offsets[_cards.find(card)]
		card.offset_transform_position = rest + Vector2(0.0, _rise_distance(card))
		# BACK overshoots the resting place and drops back onto it, so each card
		# arrives with a bit of weight instead of gliding to a halt.
		_intro_tween.tween_property(card, "offset_transform_position", rest, card_rise_duration) \
			.set_delay(card_stagger * i) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# chain() puts this after every tweener above, delays included, so the cards
	# open exactly as the last one lands however many there are.
	#
	# They stay shut until then because the screen appears under a cursor that was
	# aiming at the game a frame ago, and without the wait the shot that earned the
	# level-up would pick the upgrade too.
	_intro_tween.chain().tween_callback(_set_cards_clickable.bind(true))


# How far down a card has to start to be clear of the bottom of the screen.
#
# Measured in the card's own coordinates, because that is what the offset transform
# moves it in: the row is scaled down to a third, so a distance in screen pixels
# would only carry it a third of the way there.
func _rise_distance(card: CardUI) -> float:
	var below_screen := card.get_viewport_rect().size.y - card.get_global_rect().position.y
	var scale_y := absf(card.get_global_transform().get_scale().y)
	return below_screen / maxf(scale_y, 0.001)


func _shown_cards() -> Array[CardUI]:
	var shown: Array[CardUI] = []
	for card in _cards:
		if card.visible:
			shown.append(card)
	return shown


# CardUI reads its click in _gui_input on its own root, so muting that root is
# what makes a card inert — no second "are we accepting yet" flag to drift from.
func _set_cards_clickable(clickable: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	for card in _cards:
		card.mouse_filter = filter


func _close() -> void:
	if _intro_tween:
		_intro_tween.kill()
	# Put back where the scene has them, so a screen closed mid-intro doesn't leave
	# a card parked under the bottom edge or the backdrop stuck half faded. The next
	# offer overwrites both anyway; this is for anything that reads them in between.
	for i in _cards.size():
		_cards[i].offset_transform_position = _card_rest_offsets[i]
	if dim:
		dim.modulate.a = 1.0
	hide()


func _roll() -> Array[Upgrade]:
	if manager == null:
		push_warning("UpgradeUI has no UpgradeManager assigned")
		return []
	return manager.roll(_cards.size())


func _on_card_selected(upgrade: Upgrade) -> void:
	manager.apply(upgrade)
	_close()
	GameStateManager.instance.close_upgrades()
