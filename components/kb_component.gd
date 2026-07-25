class_name KbComponent
extends Node

#variables for knockback, a couple are needed in the enemy files
@export var body : CharacterBody2D
@export var direction_changer := Vector2.ZERO
@export var kb_decel_base_time: float = 0.5
#these two are useful for adjusting strength of kb depending on type of kb
@export var stun_kb_strength: float = 100
@export var additive_kb_strength: float = 5

var decel_time: float = kb_decel_base_time

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
#took this from the health component, seems to work, used from projectiles
static func find_in(entity: Node) -> KbComponent:
	for child in entity.get_children():
		if child is KbComponent:
			return child
	return null

func calc_vect(new_vect):
	#might scale off dmg later, for now this doesn't do much
	direction_changer = new_vect
	decel_time = kb_decel_base_time

#stuns enemies from current movement with knockback
func stun_kb_handler():
	if decel_time == 0:
		decel_time = kb_decel_base_time
		body.kb = false
		body.velocity = Vector2.ZERO
	else:
		body.velocity = direction_changer * (decel_time / kb_decel_base_time) * stun_kb_strength
	body.move_and_slide()

#non stun kb which changes position (additive to other velocities)
func additive_kb_handler():
	if decel_time == 0:
			decel_time = kb_decel_base_time
			body.kb = false
	else:
		body.global_position += direction_changer * (decel_time / kb_decel_base_time) * additive_kb_strength

#does the kb basically
func calc_kb(delta):
	decel_time = max(decel_time - delta, 0)
	if body.stun_kb:
		stun_kb_handler()
	else:
		additive_kb_handler()
