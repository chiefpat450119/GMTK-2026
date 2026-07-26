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

## Tint per rarity, multiplied into the gem art and used neat as the rarity label's
## text colour. Lives here rather than on Upgrade because it is skin, not data: the
## same tiers on a differently-drawn card want different tints, and nothing in the
## roll should be able to read a colour.
const RARITY_COLORS := {
	Upgrade.Rarity.COMMON: Color(0.5, 0.5, 0.5),
	Upgrade.Rarity.RARE: Color(0.594, 0.864, 0.94),
	Upgrade.Rarity.EPIC: Color(0.65, 0.29, 1.0),
	Upgrade.Rarity.LEGENDARY: Color(0.75, 0, 0.07),
}

const RARITY_NAMES := {
	Upgrade.Rarity.COMMON: "Common",
	Upgrade.Rarity.RARE: "Rare",
	Upgrade.Rarity.EPIC: "Epic",
	Upgrade.Rarity.LEGENDARY: "Legendary",
}

## Applied at display time rather than baked into RARITY_NAMES, so the flourish
## stays one edit away from changing and the names stay usable as plain words.
const RARITY_LABEL_FORMAT := "- %s -"

## How far the backing layer travels from white toward the rarity colour. The gem
## is a small bright shape and takes the tint neat; the back is most of the card,
## and the same colour at full strength there drowns the icon and the text sitting
## on top of it. Raise to 1.0 to have the two match exactly.
const BACK_TINT_STRENGTH := 1.0

@export var icon_rect: TextureRect
@export var title_label: Label
@export var description_label: Label
@export var normal_icon_frame: TextureRect
@export var tradeoff_icon_frame: TextureRect
@export var gem_rect: TextureRect
@export var back_rect: TextureRect
@export var rarity_label: Label

var _upgrade: Upgrade


func _ready() -> void:
	pressed.connect(_on_pressed)
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
	_apply_rarity(upgrade.rarity)


# Cards are reused across offers, so every field a rarity touches has to be
# rewritten on each setup() — falling back to the common tint rather than leaving
# the previous card's colour behind if the enum ever grows a tier this misses.
func _apply_rarity(rarity: Upgrade.Rarity) -> void:
	var color := RARITY_COLORS.get(rarity, RARITY_COLORS[Upgrade.Rarity.COMMON]) as Color
	if gem_rect:
		gem_rect.modulate = color
	if back_rect:
		back_rect.modulate = Color.WHITE.lerp(color, BACK_TINT_STRENGTH)
	if rarity_label:
		var tier_name := RARITY_NAMES.get(rarity, RARITY_NAMES[Upgrade.Rarity.COMMON]) as String
		rarity_label.text = RARITY_LABEL_FORMAT % tier_name
		# An override rather than modulate: the label carries no art of its own, so
		# the tier colour is the text colour outright instead of a multiply against
		# whatever white the theme happens to hand it.
		rarity_label.add_theme_color_override(&"font_color", color)

# Only reachable once the row has dealt this card an upgrade. A blank card left
# over from a short offer is hidden rather than disabled, so this is belt and
# braces against a press arriving before the first setup().
func _on_pressed() -> void:
	if _upgrade == null:
		return
	selected.emit(_upgrade)
	SFX.play(&"ui_press")


func _on_mouse_entered() -> void:
	if _upgrade != null:
		SFX.play(&"ui_hover")
