# Clamps a camera to the bounds of a TileMapLayer so the view never scrolls
# past the edge of the map. Drop as a child of whatever owns the camera, point
# it at that camera, and assign the map in the Inspector.
#
# Limits are applied once on ready — call apply() again if the map's used rect
# changes at runtime.

class_name CameraLimits
extends Node

@export var camera: Camera2D
@export var map: TileMapLayer


func _ready() -> void:
	if camera == null:
		push_warning("CameraLimits has no camera assigned")
		return
	if map == null:
		push_warning("CameraLimits has no map assigned")
		return

	# The map may not have its final global transform on the frame it enters
	# the tree, so read it a frame later.
	call_deferred("apply")


## Recomputes the camera's limits from the map's current used rect.
func apply() -> void:
	if camera == null or map == null:
		return

	var used := map.get_used_rect()
	var tile_size := map.tile_set.tile_size
	var top_left := map.to_global(Vector2(used.position * tile_size))
	var bottom_right := map.to_global(Vector2(used.end * tile_size))
	camera.limit_left = int(top_left.x)
	camera.limit_top = int(top_left.y)
	camera.limit_right = int(bottom_right.x)
	camera.limit_bottom = int(bottom_right.y)


func _get_configuration_warnings() -> PackedStringArray:
	if camera == null:
		return PackedStringArray(["CameraLimits needs a Camera2D assigned to clamp."])
	return PackedStringArray()
