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

var _cards: Array[CardUI] = []


func _ready() -> void:
	for child in card_row.get_children():
		var card := child as CardUI
		if card:
			card.selected.connect(_on_card_selected)
			_cards.append(card)
	offer_listener.response.connect(_on_offer)
	GameStateManager.state_changed.connect(_on_state_changed)
	hide()


func _on_state_changed(_from: int, _to: int) -> void:
	# Anything that leaves UPGRADING takes the cards down — including a Retry or a
	# quit-to-menu triggered from somewhere this screen knows nothing about.
	if GameStateManager.state != GameStateManager.GameState.UPGRADING:
		hide()


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


func _roll() -> Array[Upgrade]:
	if manager == null:
		push_warning("UpgradeUI has no UpgradeManager assigned")
		return []
	return manager.roll(_cards.size())


func _on_card_selected(upgrade: Upgrade) -> void:
	manager.apply(upgrade)
	hide()
	GameStateManager.close_upgrades()
