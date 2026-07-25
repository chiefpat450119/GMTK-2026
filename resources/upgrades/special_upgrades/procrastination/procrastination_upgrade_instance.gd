class_name ProcrastinationUpgradeInstance
extends UpgradeInstance

@onready var time_change_event_listener := GameEventListener.new()

var _below_half := false

func start():
	var upgrade_def := definition as ProcrastinationUpgrade
	
	time_change_event_listener.event = upgrade_def.time_change_event
	add_child(time_change_event_listener)
	time_change_event_listener.response.connect(_check_half_time)



func _check_half_time():
	var time_percentage : float = Player.instance.time_component.time_percentage()
	if _below_half and time_percentage >= 0.5:
		remove()
	elif !_below_half and time_percentage < 0.5:
		apply()
	
	_below_half = time_percentage < 0.5
