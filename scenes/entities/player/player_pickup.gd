class_name PlayerPickup
extends Node

@onready var player := Player.instance
@export var pickup_range: Stat

func _physics_process(_delta: float) -> void:
	var all := CollectableManagerInstance.all
	if player == null or all.is_empty():
		return

	var range_val := pickup_range.current_val()
	var range_sq := range_val * range_val
	var grab_sq := Collectable.GRAB_RADIUS * Collectable.GRAB_RADIUS
	var pos := player.global_position

	# iterate backwards: collect() erases from the array in place
	for i in range(all.size() - 1, -1, -1):
		var c := all[i]
		var dist_sq := pos.distance_squared_to(c.global_position)
		if dist_sq <= grab_sq:
			c.collect(player)
		elif dist_sq <= range_sq:
			c.start_attract(player)
