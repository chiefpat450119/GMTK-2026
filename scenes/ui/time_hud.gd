class_name TimeHud
extends CanvasLayer

@export var gear: Control
@export var hourglass: Control
@export var hourglassLabel: Label
@export var fill: ProgressBar

func _ready() -> void:
    pass


func _add_time(amount: float) -> void:
    # label should tween count up in discrete numbers
    # fill should tween up
    
    # gear rotate clockwise, then stop, and rotate anti clockwise, then clock wise again
    # hourglass should also rotate accordingly, staggered and sometimes opposite direction as the gear. 
    pass