@tool
extends Button

## A Button skinned with BUTTON_NOBACK.png as a nine-patch, captioned by a child
## Label rather than by the Button's own `text`, so the caption can carry Label-only
## styling (label_settings, outlines, per-character effects) that a Button can't.
##
## The source art is 1078x451 and a NinePatchRect always blits its corner patches
## at native pixel size, so at the sizes this is actually used at the left and
## right patches (180px each) overlap and swallow the stretchable centre whole --
## the two stripe pairs end up jammed together in the middle with no plain body
## between them. So the rect is laid out oversized and scaled down as a unit: the
## corners shrink along with everything else, instead of the patch margins having
## to be cut back until the screws and stripes distort.

# Smallest the art can be drawn at before the corner patches meet again: the
# margins (180+180 across, 85+100 down) plus a little stretchable centre. Kept in
# native pixels and scaled below, so it tracks art_scale.
const MIN_ART_SIZE := Vector2(420, 200)
# Caption inset from the drawn edges, in native pixels: left/right clear the
# stripes, and the bottom is deeper than the top so the caption sits centred in the
# orange body rather than in the body plus the purple shadow bar beneath it.
const PADDING := Vector4(100, 16, 100, 26)

## Fraction of its native size the artwork is drawn at. The default puts the art
## at roughly the 280px width the menu buttons are laid out to.
@export_range(0.05, 1.0, 0.01) var art_scale := 0.26:
	set(value):
		art_scale = value
		_apply_scale()

## The caption. Mirrored onto the child Label -- the Button's inherited `text` is
## left empty, since anything set there would draw a second caption underneath.
@export var label_text := "Button":
	set(value):
		label_text = value
		if label != null:
			label.text = value

@onready var background: NinePatchRect = $Background
@onready var label: Label = $Label


# SFX plays the UI sounds on every BaseButton that enters the tree, and this button
# asks for them itself below, so it opts out of that pass -- with both wired, every
# hover and click would play two voices of the same sample. Here rather than in
# _ready() because node_added, which is what SFX listens on, is emitted immediately
# after _enter_tree and long before the tree is ready.
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		set_meta(SFX.NO_UI_SFX, true)


func _ready() -> void:
	label.text = label_text
	resized.connect(_apply_scale)
	# Restyling or recaptioning the label changes how much room it needs, and that
	# feeds the button's minimum size below.
	label.minimum_size_changed.connect(_apply_scale)
	_apply_scale()

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)


func _on_pressed() -> void:
	SFX.play(SFX.UI_PRESS)


# A disabled button still reports the hover, but shouldn't sound like something is
# there to click.
func _on_mouse_entered() -> void:
	if not disabled:
		SFX.play(SFX.UI_HOVER)


func _apply_scale() -> void:
	# The setters run while the scene's properties are still being loaded, before
	# @onready has resolved anything; _ready() calls this again once it has.
	if background == null or label == null:
		return

	background.scale = Vector2(art_scale, art_scale)
	# The rect is positioned free-floating rather than anchored to the button, so
	# it can be sized in pre-scale space and still land exactly on the button once
	# the scale is applied. Anchoring it would let the layout overwrite this.
	background.size = size / art_scale

	# The label is anchored to the full rect, so insetting it is what centres the
	# caption on the orange body instead of on the whole drawn rect.
	var pad := Vector4(PADDING.x, PADDING.y, PADDING.z, PADDING.w) * art_scale
	label.offset_left = pad.x
	label.offset_top = pad.y
	label.offset_right = -pad.z
	label.offset_bottom = -pad.w

	# Without `text`, the Button asks for nothing on its own, so the caption has to
	# be what keeps it from collapsing -- and the art has a floor of its own.
	var caption_min := label.get_combined_minimum_size() \
			+ Vector2(pad.x + pad.z, pad.y + pad.w)
	custom_minimum_size = (MIN_ART_SIZE * art_scale).max(caption_min)
