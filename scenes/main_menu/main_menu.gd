extends StateScreen

@export var hourglass_white: Control
@export var real_icon: Control
@export var gear: Control
@export var sand: Control
@export var of: Control
@export var time: Control
@export var play_button: Button
# The block the buttons sit in. It is put where it belongs and shown; it is the
# buttons inside it that move. Its own position is still derived here because the
# block is bottom-anchored and grows off its contents -- see buttons_rest_pos().
@export var buttons_root: Control
# The buttons themselves. Every Control child enters in turn, so another button
# dropped into the column joins the stagger without anything here being retimed.
@export var button_column: Container
# The box everything above is laid out inside: a fixed 1280x720 -- the project's base
# resolution -- centred in the window. The engine scales that base to the screen for
# us (Display > Stretch is canvas_items), so this box is not what makes the menu
# scale; it is what keeps the composition together. Anchored to the window instead,
# the pieces drift apart on any aspect but 16:9 -- the buttons chase the true bottom
# edge while the title stays where it is.
@export var content: Control

var _anim_tween: Tween
var _base_white_scale: Vector2
var _base_real_scale: Vector2
# Offsets exactly as authored in the scene, per node. Positions are derived from
# these against the live parent size rather than captured once, because the title is
# anchored to the centre: a position read at one window size is wrong at every other
# one, and the animation writing that stale value back is what knocked the logo off
# centre after a resize. See layout_pos().
var _base_offsets := {}
# The button block's authored distance from the bottom edge. Kept apart from
# _base_offsets because it is the only node here whose top offset is not where it
# actually sits -- see buttons_rest_pos().
var _buttons_base_bottom := 0.0

# The white silhouette enters alone: up from under the frame, unwinding a
# three-quarter turn into the centre, then swelling. The real icon joins it for the
# climb -- both collapse up onto the title spot on the same curve, sharing one scale
# so the two silhouettes stay stacked, and the swap is a dissolve spread across that
# whole climb rather than a cut at the end of it.
const RISE_DISTANCE = 470.0     # starts below the design box, so nothing pops in
const RISE_DURATION = 0.49
const SPIN_DEGREES = 270.0      # unwinds counter-clockwise into upright
const SPIN_DURATION = 0.55
const SWELL_DELAY = 0.5         # begins as the rise lands
const SWELL_DURATION = 0.2
const SWELL_SCALE = 1.42        # peaks at ~77% of frame height, as the mockup does
const COLLAPSE_DURATION = 0.2
# where the swap sits along the climb, measured in ground covered rather than time:
# the climb eases in hard, so its first half of time is only an eighth of its
# distance, and a swap timed in seconds lands while the logo still looks parked
const SWAP_FROM_TRAVEL = 0.02
const SWAP_TO_TRAVEL = 0.3

# where the logo comes to rest, above the words
const FINAL_SCALE = 0.6
const FINAL_RISE = 120.0

const COLLAPSE_DELAY = SWELL_DELAY + SWELL_DURATION
const SWAP_TIME = COLLAPSE_DELAY + COLLAPSE_DURATION
const WORD_SLIDE_DURATION = 0.4
const DELAY_BEFORE_WORDS = 0.2
# when the last of the words starts moving. The buttons are timed off this rather
# than off a figure of their own, so retiming the words carries them along.
const LAST_WORD_DELAY = DELAY_BEFORE_WORDS + 0.4

# and the buttons come up last, under the finished title. They travel the words'
# short distance rather than the logo's, so they read as settling into place rather
# than as a third entrance, and they start before the last word has quite landed --
# a clean gap between the two reads as the intro having stalled.
const BUTTONS_ENTER_FROM = Vector2(0, 60)
const BUTTONS_SLIDE_DURATION = 0.45
const BUTTONS_DELAY = SWAP_TIME + LAST_WORD_DELAY + 0.15
# Seconds between one button setting off and the next, on the card row's reasoning:
# buttons arriving together read as one panel sliding in, and the gap is what makes
# them separate things to choose between. See CardIntro.card_stagger.
const BUTTON_STAGGER = 0.12


func _ready() -> void:
	# before super(), which can put the screen up and start the animation on the spot
	_base_white_scale = hourglass_white.scale
	_base_real_scale = real_icon.scale
	for node in animated_nodes():
		_base_offsets[node] = Vector2(node.offset_left, node.offset_top)
	# read before the animation writes to it: position/size are derived every layout
	# pass, but the offsets stay as the scene authored them until something assigns
	_buttons_base_bottom = buttons_root.offset_bottom

	# Resizing the window moves every anchored position under the animation, whether
	# the menu is up or sitting hidden behind a run, so rebuild against the new
	# layout instead of leaving the logo parked where the old one put it. The design
	# box is a fixed size, so in practice this only fires if that box is re-sized --
	# the window growing under it does not touch a single position inside it.
	layout_parent().resized.connect(_on_layout_changed)

	super()
	play_button.pressed.connect(_on_play_pressed)


# Behind the fade rather than on the press: the run is built at the darkest point,
# so the title is never seen blinking out from under the world arriving.
func _on_play_pressed() -> void:
	SceneTransition.instance.play(GameStateManager.instance.start_run)


## Re-play the intro animation each time the menu comes up.
func _on_shown() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	# Snap to the animation-start state immediately, before any frame is
	# rendered, so the finished layout is never visible. We don't need sizes
	# for alpha/rotation — only position/scale math needs a layout pass.
	hourglass_white.modulate.a = 1
	hourglass_white.rotation_degrees = SPIN_DEGREES
	real_icon.modulate.a = 0
	for word in [sand, of, time]:
		word.modulate.a = 0
	# hidden outright, not merely transparent: a Control at zero alpha still takes
	# clicks, and Play would otherwise sit live and unseen over the whole intro
	buttons_root.hide()
	# Now wait one frame so MAIN_MENU, so process_frame never fires and the await would hang forever.
	await get_tree().create_timer(0.0, true).timeout
	start_anim()
	await get_tree().create_timer(0.8).timeout
	SFX.play(&"intro_stamp_down")
	SFX.play(&"intro_stamp_down2")


func _on_hidden() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()


# Every node the animation drives. They do not share a parent -- the buttons hang off
# the screen root rather than the frame the title sits in -- so layout_pos() resolves
# each one against its own parent.
func animated_nodes() -> Array:
	return [hourglass_white, real_icon, sand, of, time, buttons_root]


func layout_parent() -> Control:
	return content


# Where a node's anchors put it at the current window size. This is what `position`
# would read if nothing had ever written to it -- the animation overwrites position
# (and with it the offsets) on every play, so the authored offsets are kept aside in
# _base_offsets and the anchor term is re-resolved here each time it is needed.
func layout_pos(node: Control) -> Vector2:
	var parent_size := (node.get_parent() as Control).size
	var offset: Vector2 = _base_offsets[node]
	return Vector2(node.anchor_left * parent_size.x, node.anchor_top * parent_size.y) + offset


# The window changed size, so every position the running animation is aiming at
# belongs to the old layout. Rebuild the sequence against the new one and fast-forward
# it to where it had got to, so a resize mid-intro re-centres without restarting the
# animation. Nothing to do while hidden -- _on_shown() rebuilds from scratch anyway.
func _on_layout_changed() -> void:
	if not visible:
		return
	if _anim_tween and _anim_tween.is_valid() and _anim_tween.is_running():
		var elapsed := _anim_tween.get_total_elapsed_time()
		start_anim(elapsed)
	else:
		apply_rest_state()


# Seconds into the climb at which it has covered the given fraction of its distance.
# The climb is a cubic ease-in, so distance is time cubed and this inverts it.
func climb_time_at(travel: float) -> float:
	return COLLAPSE_DURATION * pow(travel, 1.0 / 3.0)


# The icon's hourglass is a child drawn from the same texture as the silhouette
# (the icon's own art is only the ring behind it), so that child marks exactly where
# the silhouette has to sit for the two to register. The icon scales about a pivot
# that isn't centred on that child, so the gap between them shifts with the scale --
# hence solving for the silhouette's position rather than assuming a fixed offset.
func silhouette_pos_at(icon_pos: Vector2, node_scale: Vector2) -> Vector2:
	var icon_pivot = real_icon.size * real_icon.pivot_offset_ratio
	var gear_centre = gear.position + gear.size * 0.5
	var target = icon_pos + icon_pivot + (gear_centre - icon_pivot) * node_scale

	var white_pivot = hourglass_white.size * hourglass_white.pivot_offset_ratio
	return target - white_pivot - (hourglass_white.size * 0.5 - white_pivot) * node_scale


# node, the offset it enters from, the distance it slides, and when it starts. The
# entry offset and the slide together decide where a word ends up, so both the
# animation and a relayout mid-flight read them from here and agree on the resting spot.
func word_entries() -> Array:
	return [
		[sand, Vector2(-20, 0), Vector2(30, 0), DELAY_BEFORE_WORDS + 0.1],
		[time, Vector2(20, 0), Vector2(-30, 0), DELAY_BEFORE_WORDS + 0.25],
		[of, Vector2(0, 20), Vector2(0, -20), LAST_WORD_DELAY],
	]


# The scale the logo settles at. Both nodes share it, so the two silhouettes stay
# stacked through the dissolve.
func final_scale() -> Vector2:
	return _base_real_scale * FINAL_SCALE


# `skip_to` fast-forwards the freshly built sequence, used when a resize forces the
# animation to be rebuilt against a new layout part-way through.
func start_anim(skip_to := 0.0) -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	# Resolve every position from the anchors and the current window size, so
	# reopening the menu -- or reopening it at a different size -- still centres.
	# The silhouette's scale tweener only takes over once the rise has landed, so its
	# starting size has to be put back by hand after a previous play shrank it.
	var white_base_scale := _base_white_scale
	hourglass_white.scale = white_base_scale
	var real_rest_pos := layout_pos(real_icon)
	var real_final_pos := real_rest_pos - Vector2(0, FINAL_RISE)
	# both nodes carry the same 698x931 hourglass texture, so holding them at one
	# shared scale is what keeps the two silhouettes stacked through the dissolve
	var swell_scale := white_base_scale * SWELL_SCALE
	var end_scale := final_scale()
	# and the silhouette rests wherever it has to for the icon to surface out of it
	# without a seam -- both ends solved, so the whole climb stays registered
	var white_rest_pos := silhouette_pos_at(real_rest_pos, swell_scale)
	var white_final_pos := silhouette_pos_at(real_final_pos, end_scale)

	# the real icon waits out of sight at the swelled size, ready to climb in step
	# with the silhouette rather than appearing once the silhouette has finished
	real_icon.position = real_rest_pos
	real_icon.scale = swell_scale
	real_icon.modulate.a = 0

	hourglass_white.modulate.a = 1
	hourglass_white.rotation_degrees = SPIN_DEGREES
	hourglass_white.position = white_rest_pos + Vector2(0, RISE_DISTANCE)

	_anim_tween = create_tween()
	var tween = _anim_tween
	tween.set_parallel(true)

	# rises into the frame while unwinding to upright
	SFX.play(&"intro_slide_in")
	tween.tween_property(hourglass_white, "position", white_rest_pos, RISE_DURATION)\
			.from(white_rest_pos + Vector2(0, RISE_DISTANCE))\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(hourglass_white, "rotation_degrees", 0, SPIN_DURATION)\
			.from(SPIN_DEGREES)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)

	# swells once it lands...
	tween.tween_property(hourglass_white, "scale", swell_scale, SWELL_DURATION)\
			.from(white_base_scale)\
			.set_delay(SWELL_DELAY)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CIRC)

	# ...and from there the silhouette and the real icon climb together, on the same
	# curve and the same scale, so they read as one object the whole way up
	tween.tween_property(hourglass_white, "scale", end_scale, COLLAPSE_DURATION)\
			.from(swell_scale)\
			.set_delay(COLLAPSE_DELAY)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(hourglass_white, "position", white_final_pos, COLLAPSE_DURATION)\
			.from(white_rest_pos)\
			.set_delay(COLLAPSE_DELAY)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(real_icon, "scale", end_scale, COLLAPSE_DURATION)\
			.from(swell_scale)\
			.set_delay(COLLAPSE_DELAY)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(real_icon, "position", real_final_pos, COLLAPSE_DURATION)\
			.from(real_rest_pos)\
			.set_delay(COLLAPSE_DELAY)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)

	# the logo climbs as pure white for a moment before the skin changes under it.
	# the silhouette holds then drops away while the icon front-loads its fade to
	# cover the gap -- two shapes fading linearly past each other let the background
	# through in the middle, and the logo visibly dims as it crosses over
	var swap_delay := COLLAPSE_DELAY + climb_time_at(SWAP_FROM_TRAVEL)
	var swap_duration := climb_time_at(SWAP_TO_TRAVEL) - climb_time_at(SWAP_FROM_TRAVEL)
	tween.tween_property(hourglass_white, "modulate:a", 0, swap_duration)\
			.from(1.0)\
			.set_delay(swap_delay)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(real_icon, "modulate:a", 1, swap_duration)\
			.from(0.0)\
			.set_delay(swap_delay)
	
	# and the words come in behind the finished logo
	for entry in word_entries():
		slide_word_in(tween, entry[0], entry[1], entry[2], SWAP_TIME + entry[3])

	slide_buttons_in(tween)

	# a rebuilt sequence starts from zero, so replay the part that already happened.
	# Every tweener above declares its own .from(), so stepping lands on exactly the
	# state the old tween was in -- only measured against the new layout.
	if skip_to > 0.0:
		tween.custom_step(skip_to)


func slide_word_in(tween: Tween, word: Control, enter_from: Vector2, slide: Vector2, delay: float) -> void:
	var start := layout_pos(word) + enter_from
	word.position = start
	word.modulate.a = 0
	# absolute rather than relative, so rebuilding the tween after a resize aims at
	# the same spot instead of stacking another slide onto wherever the word sits
	tween.parallel().tween_property(word, "position", start + slide, WORD_SLIDE_DURATION)\
			.from(start)\
			.set_delay(delay)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(word, "modulate:a", 1, WORD_SLIDE_DURATION)\
			.from(0.0)\
			.set_delay(delay)


# Where the button block belongs at the current window size. It cannot go through
# layout_pos() the way the title does. The block is anchored to the bottom edge and
# grows upward off its own content, and the nine-patch buttons make it taller than the
# box it was authored at -- so Godot pins its bottom and pushes its top up past the
# authored offset, and a slide aiming at that offset would land the block low by the
# difference. The bottom is the edge the anchors actually hold, so the top is derived
# from it and the live height instead.
func buttons_rest_pos() -> Vector2:
	var parent_size := (buttons_root.get_parent() as Control).size
	# combined minimum as well as size, because the block is hidden for most of the
	# intro and a hidden Container does not re-sort
	var height := maxf(buttons_root.size.y, buttons_root.get_combined_minimum_size().y)
	var bottom := buttons_root.anchor_bottom * parent_size.y + _buttons_base_bottom
	return Vector2(
			buttons_root.anchor_left * parent_size.x + _base_offsets[buttons_root].x,
			bottom - height)


# Every button that takes part in the entrance, in the order they arrive.
func entering_buttons() -> Array[Control]:
	var result: Array[Control] = []
	if button_column == null:
		return result
	for child in button_column.get_children():
		var button := child as Control
		if button != null:
			result.append(button)
	return result


# The buttons rise into the block one after another. Each rides its own offset
# transform rather than its position, the way the card row's entrance does: position
# belongs to the VBoxContainer they sit in, and a per-button slide written there
# would be undone the next time the container sorted itself. The block only has to
# be put where it belongs and shown -- it no longer travels itself, or the stagger
# would be riding on top of a move the whole column was already making.
func slide_buttons_in(tween: Tween) -> void:
	buttons_root.position = buttons_rest_pos()
	buttons_root.modulate.a = 1
	buttons_root.hide()

	# The start *pose* is set in a callback beside the show rather than here, because
	# showing the block is itself what undoes it: every button carries a ButtonFeedback,
	# which snaps its button back to the resting pose on any visibility change, and
	# the block coming up is a visibility change for everything under it. Nothing
	# snaps mouse_filter, so that half of the start state can be set here and now,
	# where it doesn't depend on two callbacks landing on one frame in the right order.
	tween.parallel().tween_callback(_reveal_buttons).set_delay(BUTTONS_DELAY)

	var buttons := entering_buttons()
	for i in buttons.size():
		var button := buttons[i]
		var delay := BUTTONS_DELAY + BUTTON_STAGGER * i
		set_button_live(button, false)
		# The rise does nothing until the offset transform is switched on. Every
		# button here has a ButtonFeedback that has already done it; this is for one
		# that doesn't.
		button.offset_transform_enabled = true
		tween.parallel().tween_property(button, "offset_transform_position",
				Vector2.ZERO, BUTTONS_SLIDE_DURATION)\
				.from(BUTTONS_ENTER_FROM)\
				.set_delay(delay)\
				.set_ease(Tween.EASE_OUT)\
				.set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(button, "modulate:a", 1, BUTTONS_SLIDE_DURATION)\
				.from(0.0)\
				.set_delay(delay)
		# Opened on the beat it starts moving -- the same moment the block used to
		# become clickable, so nothing waits longer to be pressed than it did before.
		tween.parallel().tween_callback(set_button_live.bind(button, true)).set_delay(delay)


# Puts the block up with every button in its start pose -- in that order, since the
# show is what wakes the ButtonFeedbacks and anything written before it is what they
# undo. The first button's own rise begins on this same frame and writes the same
# pose through its .from(), so which of the two lands first doesn't matter.
func _reveal_buttons() -> void:
	buttons_root.show()
	for button in entering_buttons():
		button.offset_transform_position = BUTTONS_ENTER_FROM
		button.modulate.a = 0


# A Control at zero alpha still takes clicks, so a button waiting its turn is put
# out of the mouse's way rather than left live and unseen. Being out of the way is
# also what keeps its ButtonFeedback quiet: a hover it never hears about is a pose
# tween that never starts on the two properties this entrance is writing.
func set_button_live(button: Control, live: bool) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP if live else Control.MOUSE_FILTER_IGNORE


# Where the intro leaves everything. Used to re-centre after a resize that lands once
# the animation is already over, where there is no tween left to rebuild.
func apply_rest_state() -> void:
	var end_scale := final_scale()
	var real_final_pos := layout_pos(real_icon) - Vector2(0, FINAL_RISE)

	real_icon.position = real_final_pos
	real_icon.scale = end_scale
	real_icon.modulate.a = 1

	hourglass_white.position = silhouette_pos_at(real_final_pos, end_scale)
	hourglass_white.scale = end_scale
	hourglass_white.rotation_degrees = 0
	hourglass_white.modulate.a = 0

	for entry in word_entries():
		var word: Control = entry[0]
		word.position = layout_pos(word) + entry[1] + entry[2]
		word.modulate.a = 1

	buttons_root.position = buttons_rest_pos()
	buttons_root.modulate.a = 1
	buttons_root.show()

	for button in entering_buttons():
		button.offset_transform_enabled = true
		button.offset_transform_position = Vector2.ZERO
		button.modulate.a = 1
		set_button_live(button, true)
