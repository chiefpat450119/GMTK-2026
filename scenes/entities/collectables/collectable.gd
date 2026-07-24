class_name Collectable
extends Node2D
## Base for anything the player picks up (sand, etc).
##
## Instead of every item running its own monitoring Area2D, all active
## collectables register into a shared list. A single query source (the Player)
## iterates the list each physics frame, attracting in-range items and
## collecting ones it touches

static var all: Array[Collectable] = []

const ACCEL: float = 300.0
# will be "pickedup" once in this radius
const GRAB_RADIUS: float = 24.0

var _attract_vel: float = 0.0
var _collected: bool = false

func _enter_tree() -> void:
	all.append(self)

func _exit_tree() -> void:
	all.erase(self)

func attract_toward(target_pos: Vector2, delta: float) -> void:
	_attract_vel += ACCEL * delta
	var dir := global_position.direction_to(target_pos)
	global_position += dir * _attract_vel * delta

func collect(player: Player) -> void:
	if _collected:
		return
	_collected = true
	all.erase(self)
	_on_collected(player)
	queue_free()

func _on_collected(_player: Player) -> void:
	pass
