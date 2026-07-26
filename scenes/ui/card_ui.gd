class_name CardUI
extends Control
## One selectable upgrade card.
##
## Stateless until setup() fills it in. Emits selected() with the GunData it is
## showing so the owning GunUI can apply it.

signal selected(upgrade: Upgrade)

@export var icon_rect: TextureRect
@export var title_label: Label
@export var description_label: Label
@export var normal_icon_frame: TextureRect
@export var tradeoff_icon_frame: TextureRect

var _upgrade: Upgrade
# Whether the press this release belongs to landed on this card. A release with no
# press behind it is not a click on anything.
var _pressed_inside := false


func _ready() -> void:
	# The root handles the click, so nothing layered on top may swallow it.
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(upgrade: Upgrade) -> void:
	_upgrade = upgrade
	# A card taken down mid-press — the screen closing under the cursor — would
	# otherwise come back still owing a release, and the next stray one would pick
	# this upgrade without the player ever having pressed it.
	_pressed_inside = false
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

# Picks on release rather than on press, the way every button does: the press is
# only a claim on the click, and it stays reversible until the mouse comes up. A
# card taken the instant the button went down gives the player no way to change
# their mind, and no moment to see the card react before the screen is gone.
func _gui_input(event: InputEvent) -> void:
	if _upgrade == null:
		return
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return

	# Taken either way, so nothing behind the card sees half of a click.
	accept_event()

	if button.pressed:
		_pressed_inside = true
		return
	if not _pressed_inside:
		return
	_pressed_inside = false
	# The release is delivered here even when the cursor has wandered off, so a
	# press dragged clear of the card and let go is the standard way to back out.
	# Measured against the layout rect: the hover reaction is visual only, so the
	# card being scaled up under the cursor doesn't move the edge being tested.
	if Rect2(Vector2.ZERO, size).has_point(button.position):
		selected.emit(_upgrade)
