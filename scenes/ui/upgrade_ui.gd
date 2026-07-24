class_name UpgradeUI
extends CanvasLayer
## Modal upgrade screen.
##
## Hidden until the offer event fires. Then it rolls cards from the
## UpgradeManager, pauses the tree, and applies whichever card is clicked.
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
	hide()


func _on_offer() -> void:
	# Ignore a second offer raised while the screen is already up.
	if visible:
		return
	if manager == null:
		push_warning("UpgradeUI has no UpgradeManager assigned")
		return
	var picks := manager.roll(_cards.size())
	if picks.is_empty():
		return
	# Fewer picks than card slots once the pool runs dry.
	for i in _cards.size():
		if i < picks.size():
			_cards[i].setup(picks[i])
			_cards[i].show()
		else:
			_cards[i].hide()
	show()
	get_tree().paused = true


func _on_card_selected(upgrade: Upgrade) -> void:
	manager.apply(upgrade)
	get_tree().paused = false
	hide()
