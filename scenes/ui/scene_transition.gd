class_name SceneTransition
extends CanvasLayer
## Full-screen fade that covers a change of game state. Reached from anywhere as
## `SceneTransition.instance`, the same way GameStateManager is.
##
## The state change itself runs at the darkest point rather than on the button
## press, so the screen going down and the screen coming up are never both on
## display — and the frame that tearing a world down or building one costs is
## spent behind black instead of as a visible hitch.
##
## Sits on its own CanvasLayer above every other, because the menus it fades
## between are on layers of their own and a fade under them would cover nothing.

static var instance: SceneTransition

## Down to black.
const FADE_TO_BLACK := 0.28
## A beat fully covered, which is where the state change lands. Without it the
## rebuild happens on the exact frame the fade turns around, and the hitch reads
## as the fade stuttering.
const HOLD := 0.08
## And back out. Slower than the way in, so the arriving screen settles rather
## than snaps.
const FADE_FROM_BLACK := 0.38

## Full-screen black. Left with mouse filtering at its default STOP: while it is
## up it swallows clicks, which is what stops a second Play press from starting a
## second run mid-fade.
@export var fade: ColorRect

var _tween: Tween


func _enter_tree() -> void:
	if instance != null and instance != self:
		push_error("Duplicate SceneTransition")
		queue_free()
		return
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _ready() -> void:
	# In code rather than the .tscn, for the same reason GameStateManager does it:
	# every transition this plays runs between paused states — the menu and the
	# pause screen both pause the tree — so a tween that honoured the pause would
	# stop halfway and leave the screen black for good.
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade.modulate.a = 0.0
	fade.hide()


## Fades to black, runs `midpoint` behind the cover, then fades back.
##
## Calls made while a fade is already in flight are dropped: that transition owns
## the screen, and letting a second one in would run its midpoint over the top of
## the first — two start_run() calls, two worlds built.
func play(midpoint: Callable) -> void:
	if _tween and _tween.is_valid():
		return

	fade.modulate.a = 0.0
	fade.show()

	_tween = create_tween()
	_tween.tween_property(fade, "modulate:a", 1.0, FADE_TO_BLACK)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(midpoint)
	_tween.tween_interval(HOLD)
	_tween.tween_property(fade, "modulate:a", 0.0, FADE_FROM_BLACK)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_SINE)
	# hidden, not merely left transparent: a ColorRect at zero alpha still takes
	# clicks, and the whole screen would sit dead behind it afterwards
	_tween.tween_callback(fade.hide)
