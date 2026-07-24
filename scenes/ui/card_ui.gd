class_name CardUI
extends Control
## One selectable upgrade card.
##
## Stateless until setup() fills it in. Emits selected() with the Upgrade it is
## showing so the owning UpgradeUI can apply it.

signal selected(upgrade: Upgrade)

@export var icon_rect: TextureRect
@export var title_label: Label
@export var description_label: Label

var _upgrade: Upgrade


func _ready() -> void:
	# The root handles the click, so nothing layered on top may swallow it.
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(upgrade: Upgrade) -> void:
	_upgrade = upgrade
	title_label.text = upgrade.title
	description_label.text = upgrade.get_description()
	if upgrade.icon:
		icon_rect.texture = upgrade.icon


func _gui_input(event: InputEvent) -> void:
	if _upgrade == null:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			selected.emit(_upgrade)
