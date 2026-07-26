class_name CardUI
extends Button
## One selectable upgrade card.
##
## Stateless until setup() fills it in. Emits selected() with the Upgrade it is
## showing so the owning UpgradeUI can apply it.
##
## A Button with every state stylebox emptied in the scene, rather than a Control
## that reads raw mouse events: the card art *is* the button skin, and Button
## already owns the click rule this needs — action_mode defaults to
## ACTION_MODE_BUTTON_RELEASE, so a press only claims the click and dragging off
## the card before letting go cancels it.

signal selected(upgrade: Upgrade)

@export var icon_rect: TextureRect
@export var title_label: Label
@export var description_label: Label
@export var normal_icon_frame: TextureRect
@export var tradeoff_icon_frame: TextureRect

var _upgrade: Upgrade


func _ready() -> void:
	pressed.connect(_on_pressed)
	# The root handles the click, so nothing layered on top may swallow it.
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(upgrade: Upgrade) -> void:
	_upgrade = upgrade
	title_label.text = upgrade.title
	description_label.text = upgrade.get_description()
	if upgrade.is_tradeoff:
		tradeoff_icon_frame.visible = true
		normal_icon_frame.visible = false
	else:
		tradeoff_icon_frame.visible = false
		normal_icon_frame.visible = true
	if upgrade.icon:
		icon_rect.texture = upgrade.icon

# Only reachable once the row has dealt this card an upgrade. A blank card left
# over from a short offer is hidden rather than disabled, so this is belt and
# braces against a press arriving before the first setup().
func _on_pressed() -> void:
	if _upgrade == null:
		return
	selected.emit(_upgrade)
