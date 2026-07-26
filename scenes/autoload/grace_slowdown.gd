class_name GraceSlowdown
extends Node

@export_range(0.1, 1.0, 0.01) var grace_scale: float = 0.7
@export var ease_in: float = 0.18
@export var ease_out: float = 0.1

const _SETTLE := 3.0
const _SNAP_EPSILON := 0.002

var _current: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	var slowing := _should_slow()
	var target := grace_scale if slowing else 1.0
	var duration := ease_in if slowing else ease_out

	# delta is itself scaled by Engine.time_scale, so the ease has to run on real
	# seconds — on scaled ones the approach slows down as it succeeds, and the
	# slowdown takes longer to arrive the deeper it goes.
	var real_delta := delta / maxf(Engine.time_scale, 0.01)

	if duration <= 0.0:
		_current = target
	else:
		_current = lerpf(_current, target, 1.0 - exp(-real_delta / duration * _SETTLE))
	if absf(_current - target) < _SNAP_EPSILON:
		_current = target

	Engine.time_scale = _current


func _should_slow() -> bool:
	var manager := GameStateManager.instance
	if manager == null or manager.state != GameStateManager.GameState.PLAYING:
		return false
	if Player.instance == null:
		return false
	var clock := Player.instance.time_component
	return clock != null and clock.in_grace_period()
