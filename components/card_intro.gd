# Entrance for a row of cards on a modal pick screen.
#
# Drop as a child of the screen — the upgrade pick, the gun pick — and point it at
# that screen's row and backdrop. It is never told what the cards *are* or what
# picking one does, so both screens share one copy of the entrance the same way
# they already share ButtonFeedback for the click.
#
# The split with the owning screen: the screen decides whether it is up and which
# cards are filled in, this decides how they arrive and holds them shut until they
# have. The screen must call play() after it has shown the cards it wants, and
# cancel() when it comes down.
#
# One tween drives the whole thing. The stagger is a delay per card rather than a
# chain of callbacks, so every part shares a clock and killing the tween on an
# interrupted intro can't leave a queued callback to fire into a closed screen.

class_name CardIntro
extends Node

## The container the cards sit in. Every Control child is dealt in.
@export var card_row: Container
## Backdrop that darkens behind the cards. Optional.
@export var dim: CanvasItem
## Seconds the backdrop takes to darken. Shorter than the cards take to arrive, so
## the game is already reading as "stopped" by the time they land.
@export var dim_fade_duration: float = 0.25
## Seconds one card spends rising into place.
@export var card_rise_duration: float = 0.45
## Seconds between one card setting off and the next. Cards arriving together read
## as one object sliding in; a gap between them is what makes them separate things
## to choose from.
@export var card_stagger: float = 0.08

var _cards: Array[Control] = []
# Where each card's offset transform rests. Read from the scene so the rise ends
# on what the scene says rather than on a zero this would be assuming, and so it
# agrees with the ButtonFeedback on the card, which takes its own resting pose
# from the same place.
var _rest_offsets: Array[Vector2] = []
var _tween: Tween


func _ready() -> void:
	if card_row == null:
		push_warning("CardIntro on %s has no card_row assigned" % get_parent().name)
		return
	for child in card_row.get_children():
		var card := child as Control
		if card == null:
			continue
		# The rise rides the offset transform, which does nothing until it is
		# switched on. Cards carrying a ButtonFeedback have it on already; this is
		# for the ones that don't.
		card.offset_transform_enabled = true
		_cards.append(card)
		_rest_offsets.append(card.offset_transform_position)


## Darkens the backdrop and deals the visible cards in from under the bottom edge,
## one after another, then opens them to clicks once the last one lands.
func play() -> void:
	_set_clickable(false)
	if _tween:
		_tween.kill()

	_tween = create_tween()
	# The whole point of these screens is that the game behind them is frozen, so
	# the tween has to be explicitly exempt from the pause rather than inherit it.
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)

	if dim:
		# modulate rather than the colour itself, so the authored opacity stays the
		# thing that decides how dark "dim" is.
		dim.modulate.a = 0.0
		_tween.tween_property(dim, "modulate:a", 1.0, dim_fade_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Counted over the cards that are actually up, not their index in the row, so a
	# short offer with a hidden slot in the middle doesn't leave a gap in the deal.
	var risers := 0
	for i in _cards.size():
		var card := _cards[i]
		if not card.visible:
			continue
		var rest := _rest_offsets[i]
		card.offset_transform_position = rest + Vector2(0.0, _rise_distance(card))
		# BACK overshoots the resting place and drops back onto it, so each card
		# arrives with a bit of weight instead of gliding to a halt.
		_tween.tween_property(card, "offset_transform_position", rest, card_rise_duration) \
			.set_delay(card_stagger * risers) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		risers += 1

	# chain() puts this after every tweener above, delays included, so the cards
	# open exactly as the last one lands however many there are.
	#
	# They stay shut until then because the screen appears under a cursor that was
	# aiming at the game a frame ago, and without the wait the shot that earned the
	# level-up would pick the upgrade too.
	_tween.chain().tween_callback(_set_clickable.bind(true))


## Stops an intro in flight and puts everything back where the scene has it, so a
## screen closed mid-rise doesn't leave a card parked under the bottom edge or the
## backdrop stuck half faded. The next play() overwrites both anyway; this is for
## anything that reads them in between.
func cancel() -> void:
	if _tween:
		_tween.kill()
	for i in _cards.size():
		_cards[i].offset_transform_position = _rest_offsets[i]
	if dim:
		dim.modulate.a = 1.0


# How far down a card has to start to be clear of the bottom of the screen.
#
# Measured in the card's own coordinates, because that is what the offset transform
# moves it in: the row is scaled down to a third, so a distance in screen pixels
# would only carry it a third of the way there.
func _rise_distance(card: Control) -> float:
	var below_screen := card.get_viewport_rect().size.y - card.get_global_rect().position.y
	var scale_y := absf(card.get_global_transform().get_scale().y)
	return below_screen / maxf(scale_y, 0.001)


# Muting the card's own root is what makes it inert — no second "are we accepting
# yet" flag for the card scripts to drift from.
func _set_clickable(clickable: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	for card in _cards:
		card.mouse_filter = filter
