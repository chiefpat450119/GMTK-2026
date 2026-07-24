extends Node2D

@onready var cd := Cooldown.new(1)

func _ready():
    cd.start()

func _process(delta: float) -> void:
    cd.tick(delta)

    if cd.is_done():
        cd.start()
        CollectableManagerInstance.spawn_sand(
            Player.instance.global_position 
            + randf_range(50, 200) * Vector2.from_angle(randf_range(-180, 180)))