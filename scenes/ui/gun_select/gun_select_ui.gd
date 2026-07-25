class_name GunSelectUI
extends CanvasLayer

@export var gun_pool : Array[GunData]
@export var offer_listener: GameEventListener

@export var card_row: HBoxContainer

var _cards: Array[GunCardUI] = []


func _ready() -> void:
	for child in card_row.get_children():
		var card := child as GunCardUI
		if card:
			card.selected.connect(_on_card_selected)
			_cards.append(card)
	offer_listener.response.connect(_on_offer)
	hide()


func _on_card_selected(gun: GunData):
	var gun_scene := gun.gun_scene.instantiate()
	Player.instance.add_child(gun_scene)
	get_tree().paused = false
	hide()

func _on_offer():
	# Ignore a second offer raised while the screen is already up.
	if visible:
		return
		
	var picks := gun_pool
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
