extends ProgressBar

var health_component : HealthComponent
var max_hp : float
var current_health : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_component = get_parent().get_parent().health_component
	max_hp = health_component.max_hp.current_val()
	current_health = health_component.hp
	max_hp = current_health
	self.max_value = max_hp

#updates bar, might be possible to do this without a process
func _process(delta: float) -> void:
	current_health = health_component.hp
	self.value = current_health
	if current_health != max_hp:
		self.visible = true
	else:
		self.visible = false
