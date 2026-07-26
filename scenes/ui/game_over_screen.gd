extends StateScreen

@export var retry_button: Button
@export var menu_button: Button

@export_group("Intro")
@export var big_gear: Control
@export var small_gear_left: Control
@export var small_gear_right: Control
@export var hourglass: Control
@export var dim: Control
@export var title: Control
@export var buttons_root: Control

const GEAR_SPIN_DEGREES = 220.0
const GEAR_SPIN_DURATION = 0.55
const GEAR_STAGGER = 0.07
const GEAR_ENTER_SCALE = 0.82
const GEAR_FADE_FRACTION = 0.7

const HOURGLASS_DELAY = 0.18
const HOURGLASS_DURATION = 0.4
const HOURGLASS_ENTER_SCALE = 0.88

const BANNER_DELAY = GEAR_SPIN_DURATION + GEAR_STAGGER * 2
const BANNER_DURATION = 0.28
const BANNER_DROP = 14.0
const TITLE_DELAY = BANNER_DELAY + 0.08
const TITLE_DURATION = 0.26
const TITLE_ENTER_SCALE = 1.12

const BUTTONS_ENTER_FROM = Vector2(0, 60)
const BUTTONS_DURATION = 0.45
const BUTTONS_DELAY = TITLE_DELAY + 0.18

var _rest_offsets := {}
var _rest_rotations := {}
var _rest_scales := {}

var _intro_tween: Tween


func _ready() -> void:
	for node in _animated_nodes():
		node.offset_transform_enabled = true
		_rest_offsets[node] = node.offset_transform_position
		_rest_rotations[node] = node.offset_transform_rotation
		_rest_scales[node] = node.offset_transform_scale

	super()
	retry_button.pressed.connect(GameStateManager.instance.start_run)
	menu_button.pressed.connect(GameStateManager.instance.to_main_menu)


func _animated_nodes() -> Array:
	return [big_gear, small_gear_left, small_gear_right, hourglass, dim, title, buttons_root]


func _gears() -> Array:
	return [big_gear, small_gear_left, small_gear_right]


func _on_shown() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()

	_apply_intro_start()

	await get_tree().create_timer(0.0, true).timeout
	if not visible:
		return
	_start_intro()


func _on_hidden() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_apply_rest_state()


func _apply_intro_start() -> void:
	for node in _animated_nodes():
		node.modulate.a = 0.0
	buttons_root.hide()
	_set_buttons_clickable(false)


func _apply_rest_state() -> void:
	for node in _animated_nodes():
		node.offset_transform_position = _rest_offsets[node]
		node.offset_transform_rotation = _rest_rotations[node]
		node.offset_transform_scale = _rest_scales[node]
		node.modulate.a = 1.0
	buttons_root.show()
	_set_buttons_clickable(true)


func _start_intro() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()

	_intro_tween = create_tween()
	_intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_intro_tween.set_parallel(true)
	var tween := _intro_tween

	var gears := _gears()
	for i in gears.size():
		var spin_sign := -1.0 if i == 0 else 1.0
		_spin_gear_in(tween, gears[i], spin_sign, GEAR_STAGGER * i)

	var hourglass_rest: Vector2 = _rest_scales[hourglass]
	tween.tween_property(hourglass, "modulate:a", 1.0, HOURGLASS_DURATION) \
			.from(0.0) \
			.set_delay(HOURGLASS_DELAY)
	tween.tween_property(hourglass, "offset_transform_scale", hourglass_rest, HOURGLASS_DURATION) \
			.from(hourglass_rest * HOURGLASS_ENTER_SCALE) \
			.set_delay(HOURGLASS_DELAY) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var dim_rest: Vector2 = _rest_offsets[dim]
	tween.tween_property(dim, "modulate:a", 1.0, BANNER_DURATION) \
			.from(0.0) \
			.set_delay(BANNER_DELAY)
	tween.tween_property(dim, "offset_transform_position", dim_rest, BANNER_DURATION) \
			.from(dim_rest - Vector2(0.0, BANNER_DROP)) \
			.set_delay(BANNER_DELAY) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var title_rest: Vector2 = _rest_scales[title]
	tween.tween_property(title, "modulate:a", 1.0, TITLE_DURATION) \
			.from(0.0) \
			.set_delay(TITLE_DELAY)
	tween.tween_property(title, "offset_transform_scale", title_rest, TITLE_DURATION) \
			.from(title_rest * TITLE_ENTER_SCALE) \
			.set_delay(TITLE_DELAY) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_slide_buttons_in(tween)


func _spin_gear_in(tween: Tween, gear: Control, spin_sign: float, delay: float) -> void:
	var rest_rotation: float = _rest_rotations[gear]
	var rest_scale: Vector2 = _rest_scales[gear]

	tween.tween_property(gear, "offset_transform_rotation", rest_rotation, GEAR_SPIN_DURATION) \
			.from(rest_rotation + deg_to_rad(GEAR_SPIN_DEGREES * spin_sign)) \
			.set_delay(delay) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(gear, "offset_transform_scale", rest_scale, GEAR_SPIN_DURATION) \
			.from(rest_scale * GEAR_ENTER_SCALE) \
			.set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(gear, "modulate:a", 1.0, GEAR_SPIN_DURATION * GEAR_FADE_FRACTION) \
			.from(0.0) \
			.set_delay(delay)


func _slide_buttons_in(tween: Tween) -> void:
	var rest: Vector2 = _rest_offsets[buttons_root]
	var start := rest + BUTTONS_ENTER_FROM
	buttons_root.hide()
	buttons_root.offset_transform_position = start
	buttons_root.modulate.a = 0.0

	tween.tween_callback(buttons_root.show).set_delay(BUTTONS_DELAY)
	tween.tween_property(buttons_root, "offset_transform_position", rest, BUTTONS_DURATION) \
			.from(start) \
			.set_delay(BUTTONS_DELAY) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttons_root, "modulate:a", 1.0, BUTTONS_DURATION) \
			.from(0.0) \
			.set_delay(BUTTONS_DELAY)
	tween.tween_callback(_set_buttons_clickable.bind(true)) \
			.set_delay(BUTTONS_DELAY + BUTTONS_DURATION)


func _set_buttons_clickable(clickable: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	retry_button.mouse_filter = filter
	menu_button.mouse_filter = filter
