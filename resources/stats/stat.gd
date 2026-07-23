class_name Stat
extends Resource
## Basic stat to be used by player and enemies
##
## stores base val, min and max
## access value with current_val()
## add modifier with add_mod()
## remove with remove_mod()
## !!!!Upgrades that add mods should be responsible for 
##  removing them 

@export var stat_name := "New Stat"
@export var base_val : float = 0.0
@export var min_val : float = -INF
@export var max_val : float = INF

var mods : Array[Modifier]


# returns the current value with all active modifiers applied
# pass in base value to use some external default value
func current_val(base : float = base_val) -> float:
	var add_total := 0.0
	var mult_total := 1.0
	
	for mod in mods:
		match mod.operation:
			Modifier.Operation.ADD:
				add_total += mod.value
			Modifier.Operation.MULT:
				mult_total += mod.value
	
	var val := (base + add_total) * mult_total
	return clamp(val, min_val, max_val)

# creates a new Modifier and appends it to the array
func add_mod(id: StringName, val: float, op: Modifier.Operation):
	var mod := Modifier.new(id, val, op)
	mods.append(mod)

# finds modifier with matching id and removes it from array
func remove_mod(id: StringName):
	mods = mods.filter(
		func(mod: Modifier) -> bool:
			return mod.id != id
	)
	
