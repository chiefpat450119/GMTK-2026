extends Control

@export var hourglass_white: Control
@export var real_icon: Control
@export var sand: Control
@export var of: Control
@export var time: Control


const DELAY_AFTER_LOGO = 0
const WORD_SLIDE_DURATION = 0.4
const DELAY_BEFORE_WORDS = 0.2


func _ready():
	start_anim()


func start_anim() -> void:
	var original_scale = hourglass_white.scale
	var original_scale_real = real_icon.scale

	hourglass_white.modulate.a = 0
	hourglass_white.rotation_degrees = -65
	hourglass_white.scale *= 1.5
	# real_icon.scale *= 5
	real_icon.modulate.a = 0

	# the words start invisible and offset, then slide + fade in once the logo lands
	for word in [sand, of, time]:
		word.modulate.a = 0
	sand.position.x -= 20
	time.position.x += 20
	of.position.y += 20

	var tween = create_tween()

	# hourglass spins/scales into view
	tween.parallel().tween_property(hourglass_white, "modulate:a", 1, 0.4)
	tween.parallel().tween_property(hourglass_white, "rotation_degrees", 0, 0.5)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(hourglass_white, "scale", original_scale, 0.2)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CIRC)

	# the real icon slams in on top of it
	tween.parallel().tween_property(real_icon, "modulate:a", 1, 0.3).set_delay(0.5)
	tween.tween_callback(func(): hourglass_white.modulate.a = 0)
	tween.parallel().tween_property(real_icon, "scale", original_scale_real, 0.15)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)

	tween.tween_callback(func():animate_words())
	# icon settles into the title layout, and the words come with it
	tween.parallel().tween_property(real_icon, "scale", original_scale_real * 0.6, 0.3)\
			.set_delay(DELAY_AFTER_LOGO)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(real_icon, "position:y", -120, 0.8)\
			.set_delay(DELAY_AFTER_LOGO)\
			.as_relative()\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)


func animate_words() -> void:
	var tween = create_tween()
	var start = DELAY_AFTER_LOGO + DELAY_BEFORE_WORDS
	slide_word_in(tween, sand, Vector2(30, 0), start + 0.1)
	slide_word_in(tween, time, Vector2(-30, 0), start + 0.25)
	slide_word_in(tween, of, Vector2(0, -20), start + 0.4)


func slide_word_in(tween: Tween, word: Control, offset: Vector2, delay: float) -> void:
	tween.parallel().tween_property(word, "position", offset, WORD_SLIDE_DURATION)\
			.set_delay(delay)\
			.as_relative()\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(word, "modulate:a", 1, WORD_SLIDE_DURATION)\
			.set_delay(delay)
