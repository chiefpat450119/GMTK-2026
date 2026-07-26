class_name UpgradeInstance
extends Node

var definition: Upgrade


func _init(upgrade_definition: Upgrade) -> void:
	definition = upgrade_definition

# to be overridden by inhereted objcet
func start():
	apply()

func apply() -> void:
	if definition.collect_event:
		definition.collect_event.raise()
	
	for effect_index in definition.effects.size():
		var effect := definition.effects[effect_index]
		
		if effect.target_stat == null:
			continue
			
		effect.target_stat.add_mod(
			_get_mod_id(effect_index),
			effect.value,
			effect.operation
		)


func remove() -> void:
	for effect_index in definition.effects.size():
		var effect := definition.effects[effect_index]

		if effect.target_stat == null:
			continue

		effect.target_stat.remove_mod(
			_get_mod_id(effect_index)
		)


func _get_mod_id(effect_index: int) -> StringName:
	return StringName(
		"upgrade:%s:%d:%d" % [
			definition.id,
			get_instance_id(),
			effect_index
		]
	)
