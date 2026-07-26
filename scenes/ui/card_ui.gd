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


func _ready() -> void:
	# The root handles the click, so nothing layered on top may swallow it.
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	# SFX auto-wires BaseButtons, and this is a plain Control handling its own
	# clicks, so it has to ask for the UI sounds itself.
	mouse_entered.connect(_on_mouse_entered)


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

func _gui_input(event: InputEvent) -> void:
	if _upgrade == null:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			SFX.play(&"ui_press")
			selected.emit(_upgrade)


func _on_mouse_entered() -> void:
	if _upgrade != null:
		SFX.play(&"ui_hover")
