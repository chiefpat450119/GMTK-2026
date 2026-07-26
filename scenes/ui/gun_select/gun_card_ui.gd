class_name GunCardUI
extends Button
## One selectable gun card.
##
## Stateless until setup() fills it in. Emits selected() with the GunData it is
## showing so the owning GunSelectUI can equip it.
##
## Shaped like CardUI down to the class it extends: a Button with every state
## stylebox emptied in the scene, so the card art is the whole skin and Button's
## own click rule applies — action_mode defaults to ACTION_MODE_BUTTON_RELEASE, so
## a press only claims the click and dragging off the card cancels it.

signal selected(gun: GunData)

@export var icon_rect: TextureRect
@export var title_label: Label
@export var description_label: Label

var _gun: GunData


func _ready() -> void:
	pressed.connect(_on_pressed)
	# The root handles the click, so nothing layered on top may swallow it.
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(gun: GunData) -> void:
	_gun = gun

	title_label.text = gun.title
	description_label.text = gun.description
	icon_rect.texture = gun.icon


func _on_pressed() -> void:
	if _gun == null:
		return
	selected.emit(_gun)
