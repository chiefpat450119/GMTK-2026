extends Camera2D

## Clamps the camera to the bounds of a TileMapLayer so the view never
## scrolls past the edge of the map. Assign the map in the Inspector.

@export var map: TileMapLayer

func _ready() -> void:
	if map:
		call_deferred("_apply_limits", map)


func _apply_limits(map: TileMapLayer) -> void:
	var used := map.get_used_rect()
	var tile_size := map.tile_set.tile_size
	var top_left := map.to_global(Vector2(used.position * tile_size))
	var bottom_right := map.to_global(Vector2(used.end * tile_size))
	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(bottom_right.x)
	limit_bottom = int(bottom_right.y)
