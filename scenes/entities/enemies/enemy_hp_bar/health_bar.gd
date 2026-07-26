extends ProgressBar

@export var health_component : HealthComponent
var parent
@export var displacement : Vector2 #relevant when rotating
var max_hp : float
var current_health : float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	max_hp = health_component.max_hp.current_val()
	current_health = health_component.hp
	# displacement = Vector2(-size.x / 2, position.y) #x is centered for now
	max_hp = current_health #this is an assumption
	self.max_value = max_hp

func _process(delta: float) -> void:
	#this first part is needed if the enemy is rotating, eg bash enemy
	rotation = -parent.global_rotation
	global_position = parent.global_position
	global_position += displacement
	
	#updates health bar's data
	current_health = health_component.hp
	self.value = current_health
	if current_health < max_hp:
		self.visible = true
	else:
		self.visible = false #set to false if you want hp bar to disappear on max hp
