# Draws every shader in the game once as a run starts, so none of them compiles
# partway through one.
#
# On the web export the renderer is Compatibility/WebGL2, and there a canvas shader
# is compiled and linked the first frame something actually *draws* with it — not
# when the scene is loaded and not when the node enters the tree. Chrome puts that
# through ANGLE's GLSL-to-HLSL translation, which is slow enough to cost a whole
# second on one frame.
#
# That is invisible for the effects that fire early: the first enemy hit pays for
# hit_burst in the opening seconds, where a hitch reads as the page still settling.
# ColorDrain and TimeVignette are the problem. Both sit in the HUD hidden from
# _ready(), both wait for the run clock to fall past `appear_at`, and both are
# full-screen passes reading hint_screen_texture — so the first time the player
# drops low, two full-screen programs compile and the backbuffer copy is allocated,
# all on the frame that draws them, well into a run where a freeze costs a life.
#
# So it's paid here instead, from start_run(), which is the midpoint SceneTransition
# runs behind a fully black screen — the same cover the world teardown and rebuild
# already hide under, and the one place in the game where a stalled frame costs
# nothing. Compiled programs live as long as the GL context, so the first run through
# is enough for the whole session; every run after it returns immediately.
#
# Adding a shader to the game means adding its scene to SCENES. A shader that isn't
# listed still works; it just compiles wherever it first draws, which is the hitch
# this exists to avoid.

class_name ShaderPrewarm
extends CanvasLayer

## One instance of each is drawn. Every scene carrying a ShaderMaterial or a
## particle process material belongs here, whether or not it's on screen early —
## listing an early one costs a few sub-pixel draws at boot and nothing else.
const SCENES: Array[PackedScene] = [
	preload("res://scenes/effects/disintegrate_effect.tscn"),
	preload("res://scenes/effects/hit_burst.tscn"),
	preload("res://scenes/effects/steam_effect.tscn"),
	preload("res://scenes/ui/color_drain.tscn"),
	preload("res://scenes/ui/time_vignette.tscn"),
]

const SHRINK := 0.01
const FRAMES := 2


static var _warmed := false


static func run(host: Node) -> void:
	if _warmed:
		return
	_warmed = true
	host.add_child(ShaderPrewarm.new())


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = -128
	scale = Vector2(SHRINK, SHRINK)
	_warm()


func _warm() -> void:
	var total := Time.get_ticks_msec()
	var report := PackedStringArray()

	for packed in SCENES:
		var started := Time.get_ticks_msec()
		var node := packed.instantiate()
		add_child(node)
		_prepare(node)

		for _i in FRAMES:
			await RenderingServer.frame_post_draw

		report.append("%s %dms" % [packed.resource_path.get_file(), Time.get_ticks_msec() - started])

	queue_free()


func _prepare(node: Node) -> void:
	var item := node as CanvasItem
	if item == null:
		return
	item.set_process(false)
	item.set_physics_process(false)
	item.visible = true

	var sprite := node as Sprite2D
	if sprite != null and sprite.texture == null:
		sprite.texture = _placeholder()


func _placeholder() -> Texture2D:
	var img := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)
