class_name Modifier
extends RefCounted
## Modifier to be added to Stat
##
## should not be instantiated directly. Instead use Stat.add_mod(..)
## Make sure to give the mod a unique id StringName
## StringNames should be preceded by a '&' e.g. &"my StringName"

enum Operation {
	ADD,
	MULT,
}

var id: StringName
var value: float
var operation: Operation

func _init(_id : StringName, _val: float, _op: Operation):
	id = _id
	value = _val
	operation = _op
