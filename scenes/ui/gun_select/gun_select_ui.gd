class_name GunSelectUI
extends CanvasLayer
## Modal gun pick screen. Up at the top of every run, before the first wave.
##
## Same split as UpgradeUI, for the same reason: *whether* it is up follows
## GameStateManager's SELECTING_GUN state, *what* it shows follows the offer
## event. It never touches get_tree().paused — the manager owns that flag, and a
## screen that unpaused on its own would leave the manager believing the game was
## still frozen.
##
## How the cards arrive belongs to the CardIntro child, shared with the upgrade
## screen so the two entrances can't drift apart.
##
## The root's process_mode must stay ALWAYS or the cards go dead while paused.

@export var gun_pool: Array[GunData]
@export var offer_listener: GameEventListener
@export var card_row: HBoxContainer
@export var intro: CardIntro

var _cards: Array[GunCardUI] = []


func _ready() -> void:
	for child in card_row.get_children():
		var card := child as GunCardUI
		if card:
			card.selected.connect(_on_card_selected)
			_cards.append(card)
	offer_listener.response.connect(_on_offer)
	# Guarded because this screen is also instanced on its own in the debug
	# harness, where there is no manager and the offer is raised by hand.
	if GameStateManager.instance:
		GameStateManager.instance.state_changed.connect(_on_state_changed)
	hide()


func _on_state_changed(_from: int, _to: int) -> void:
	# Anything that leaves SELECTING_GUN takes the cards down — including a quit to
	# menu, or a Retry raised from somewhere this screen knows nothing about.
	if GameStateManager.instance.state != GameStateManager.GameState.SELECTING_GUN:
		_close()


func _on_offer() -> void:
	# Ignore a second offer raised while the screen is already up.
	if visible:
		return

	var picks := gun_pool
	if picks.is_empty():
		# Nothing to choose from. Hand the run over rather than leaving it frozen
		# behind a screen that will never show anything.
		GameStateManager.instance.close_gun_select()
		push_warning("Gun pool empty")
		return

	# Fewer picks than card slots once the pool runs dry.
	for i in _cards.size():
		if i < picks.size():
			_cards[i].setup(picks[i])
			_cards[i].show()
		else:
			_cards[i].hide()
	show()
	# After the cards are filled and shown, so the intro deals in exactly the ones
	# this offer put up.
	intro.play()


func _close() -> void:
	intro.cancel()
	hide()


func _on_card_selected(gun: GunData) -> void:
	Player.instance.gun_holder.equip_single(gun)
	_close()
	GameStateManager.instance.close_gun_select()
