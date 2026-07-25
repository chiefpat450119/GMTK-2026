extends Control

@export var hourglass_white: Control
@export var real_icon: Control
@export var gear: Control
@export var sand: Control
@export var of: Control
@export var time: Control


# The white silhouette enters alone: up from under the frame, unwinding a
# three-quarter turn into the centre, then swelling. The real icon joins it for the
# climb -- both collapse up onto the title spot on the same curve, sharing one scale
# so the two silhouettes stay stacked, and the swap is a dissolve spread across that
# whole climb rather than a cut at the end of it.
const RISE_DISTANCE = 470.0     # starts just below the viewport, so nothing pops in
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


func _ready():
	start_anim()


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


func start_anim() -> void:
	var white_base_scale = hourglass_white.scale
	var real_rest_pos = real_icon.position
	var real_final_pos = real_rest_pos - Vector2(0, FINAL_RISE)
	# both nodes carry the same 698x931 hourglass texture, so holding them at one
	# shared scale is what keeps the two silhouettes stacked through the dissolve
	var swell_scale = white_base_scale * SWELL_SCALE
	var final_scale = real_icon.scale * FINAL_SCALE
	# and the silhouette rests wherever it has to for the icon to surface out of it
	# without a seam -- both ends solved, so the whole climb stays registered
	var white_rest_pos = silhouette_pos_at(real_rest_pos, swell_scale)
	var white_final_pos = silhouette_pos_at(real_final_pos, final_scale)

	# the real icon waits out of sight at the swelled size, ready to climb in step
	# with the silhouette rather than appearing once the silhouette has finished
	real_icon.scale = swell_scale
	real_icon.modulate.a = 0

	hourglass_white.modulate.a = 1
	hourglass_white.rotation_degrees = SPIN_DEGREES
	hourglass_white.position = white_rest_pos + Vector2(0, RISE_DISTANCE)

	# the words start invisible and offset, then slide + fade in once the logo lands
	for word in [sand, of, time]:
		word.modulate.a = 0
	sand.position.x -= 20
	time.position.x += 20
	of.position.y += 20

	var tween = create_tween()
	tween.set_parallel(true)

	# rises into the frame while unwinding to upright
	tween.tween_property(hourglass_white, "position", white_rest_pos, RISE_DURATION)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(hourglass_white, "rotation_degrees", 0, SPIN_DURATION)\
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
	tween.tween_property(hourglass_white, "scale", final_scale, COLLAPSE_DURATION)\
			.from(swell_scale)\
			.set_delay(COLLAPSE_DELAY)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(hourglass_white, "position", white_final_pos, COLLAPSE_DURATION)\
			.from(white_rest_pos)\
			.set_delay(COLLAPSE_DELAY)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(real_icon, "scale", final_scale, COLLAPSE_DURATION)\
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
	var swap_delay = COLLAPSE_DELAY + climb_time_at(SWAP_FROM_TRAVEL)
	var swap_duration = climb_time_at(SWAP_TO_TRAVEL) - climb_time_at(SWAP_FROM_TRAVEL)
	tween.tween_property(hourglass_white, "modulate:a", 0, swap_duration)\
			.set_delay(swap_delay)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(real_icon, "modulate:a", 1, swap_duration)\
			.set_delay(swap_delay)

	# and the words come in behind the finished logo
	tween.tween_callback(animate_words).set_delay(SWAP_TIME)


func animate_words() -> void:
	var tween = create_tween()
	slide_word_in(tween, sand, Vector2(30, 0), DELAY_BEFORE_WORDS + 0.1)
	slide_word_in(tween, time, Vector2(-30, 0), DELAY_BEFORE_WORDS + 0.25)
	slide_word_in(tween, of, Vector2(0, -20), DELAY_BEFORE_WORDS + 0.4)


func slide_word_in(tween: Tween, word: Control, offset: Vector2, delay: float) -> void:
	tween.parallel().tween_property(word, "position", offset, WORD_SLIDE_DURATION)\
			.set_delay(delay)\
			.as_relative()\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(word, "modulate:a", 1, WORD_SLIDE_DURATION)\
			.set_delay(delay)
