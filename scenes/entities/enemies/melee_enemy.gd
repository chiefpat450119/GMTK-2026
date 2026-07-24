class_name MeleeEnemy
extends Enemy

@export var attack_cd: float
@export var hurtbox: Area2D

@onready var attack_cooldown := Cooldown.new(attack_cd)

func _ready() -> void:
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(_delta: float) -> void:
	move_towards_player(1)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	if not attack_cooldown.is_done():
		return
	
	hit(1)
