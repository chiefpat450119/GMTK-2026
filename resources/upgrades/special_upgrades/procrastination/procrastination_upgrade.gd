class_name ProcrastinationUpgrade
extends Upgrade

@export var time_change_event : GameEvent



func create_instance() -> UpgradeInstance:
	return ProcrastinationUpgradeInstance.new(self)
