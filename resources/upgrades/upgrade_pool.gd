class_name UpgradePool
extends Resource
## The draw source: a flat list of Upgrades.
##
## Pure data. Rolling/weighting and stack tracking live in UpgradeManager,
## which owns the run-time state.

@export var upgrades: Array[Upgrade] = []
