extends CharacterBody2D

@export var speed : float = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dir = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = dir * speed
	move_and_slide()
