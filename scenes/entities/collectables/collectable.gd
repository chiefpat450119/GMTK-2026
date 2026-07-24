class_name Collectable
extends Node2D
## Base for anything the player picks up (sand, etc).

# will be "pickedup" once in this radius
const GRAB_RADIUS: float = 24.0

# homing tween, exposed so the movement curve can be tuned per collectable
@export var attract_duration: float = 0.4
@export var attract_trans: Tween.TransitionType = Tween.TRANS_CUBIC
@export var attract_ease: Tween.EaseType = Tween.EASE_IN

var _attracting: bool = false
var _collected: bool = false


func _exit_tree() -> void:
	# safety net for removals that bypass collect() (timed despawn, scene change)
	CollectableManagerInstance.erase(self)


# starts homing toward the player. idempotent so the player can call it every
# frame the item is in range. the endpoint is sampled live inside the tween, so
# the item keeps tracking the player as they move.
func start_attract(player: Player) -> void:
	if _attracting:
		return
	_attracting = true

	var start := global_position
	var step := func(w: float) -> void:
		global_position = start.lerp(player.global_position, w)

	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(attract_trans).set_ease(attract_ease)
	tween.tween_method(step, 0.0, 1.0, attract_duration)
	# if the player outran the pull, let it re-home from the new position
	tween.finished.connect(func() -> void: _attracting = false)

func collect(player: Player) -> void:
	if _collected:
		return
	_collected = true
	_on_collected(player)
	queue_free()

func _on_collected(_player: Player) -> void:
	pass
